class FacebookCanvasController < ApplicationController
  include ActionView::Helpers::JavaScriptHelper

  layout 'facebook_canvas'
  
  # Rails will invalidate the session if CSRF protection is enabled and
  # the csrf_token isn't valid.  Facebook doesn't pass a csrf_token.
  skip_before_filter :verify_authenticity_token
  
  before_filter :set_p3p
  before_filter :initialize_koala, :except => ['auth_callback']

  # All users loading our canvas page enter here.
  def index
    
    # Check to see if there are any app requests to handle
    if params[:request_ids]
      @request_ids = params[:request_ids].split(',')
    end

    # If user is accepting multiple requests or didn't specify any,
    # get all requests and display them to the user.
    @app_requests = app_api.get_connections(@signed_request['user_id'], 'apprequests')
    if @app_requests
      @app_requests.each do |fb_request|
        if fb_request['data']
          begin
            fb_request['data'] = Yajl::Parser.parse(fb_request['data'])
          rescue
          end
        end
      end
    end
    
    if @app_requests.length > 0
      render 'display_requests' and return
    end
  end
  
  def auth_callback
    if params[:error]
      redirect_to root_url
    else
      redirect_to "https://apps.facebook.com/#{Worlize.config['facebook']['app_name']}/"
    end
  end

  def link_account
    if current_user.nil?
      render :json => {
        'success' => false,
        'message' => 'A user must be logged in to be able to link a facebook account'
      } and return
    end
    
    if current_user.authentications.where(:provider => 'facebook').count > 0
      render :json => {
        'success' => false,
        'message' => 'There is already a facebook account linked to the current user.'
      } and return      
    end

    authentication = current_user.authentications.create(
      :provider => 'facebook',
      :uid => @signed_request['user_id'],
      :token => @signed_request['oauth_token']
    )

    if authentication.persisted?
      render :json => {
        'success' => true
      }
    else
      render :json => {
        'success' => false,
        'message' => authentication.errors.full_messages.join('; ')
      }
    end
  end

  def enter_worlize
    dest_url = dashboard_url

    if current_user.nil?
      # make sure we authenticate with the current user.
      session[:return_to] = dest_url
      dest_url = "#{request.scheme}://#{request.host_with_port}/auth/facebook"
    end

    render :text => '<script>top.location.href="' + escape_javascript(dest_url) + '"</script>',
           :content_type => 'text/html'
  end

  def handle_request
    # If we're called by another action, @request_id_to_handle will be
    # pre-populated by the caller.
    @request_id_to_handle ||= params[:id]

    begin
      @request_to_handle = user_api.get_object(@request_id_to_handle)
      user_api.delete_object(@request_id_to_handle)
    rescue Exception => e
      render :text => "There was an error while handling the request:\n#{e.to_s}", :status_code => 500
      return
    end

    if @request_to_handle && @request_to_handle['data']
      begin
        @request_to_handle['data'] = Yajl::Parser.parse(@request_to_handle['data'])
      rescue
        render :text => "Invalid request data", :status => 500 and return
      end
    end

    data = @request_to_handle['data']
    action = data['action']

    if action == 'join'
      dest_url = join_user_url(data['inviter_guid'])
    else
      dest_url = dashboard_url
    end

    authentication = Authentication.where(:provider => 'facebook', :uid => @signed_request['user_id']).first
    if current_user.nil?
      # make sure we authenticate with the current user.
      session[:return_to] = dest_url
      dest_url = "#{request.scheme}://#{request.host_with_port}/auth/facebook"
    end

    render :text => '<script>top.location.href="' + escape_javascript(dest_url) + '"</script>',
           :content_type => 'text/html'
  end

  def ignore_request
    fb_api = Koala::Facebook::API.new(oauth.get_app_access_token)
    fb_api.delete_object(params[:id])
    render :nothing => true
  end

  private

  def log_headers
    Rails.logger.debug "Headers:"
    request.headers.each_pair do |k,v|
      Rails.logger.debug "#{k.slice(5..k.length)} - #{v}" if k.index('HTTP_') == 0
    end
    # Rails.logger.debug "Session:\n#{session.to_yaml}"
  end

  def set_p3p
    response.headers["P3P"]='CP="CAO PSA OUR"'
  end
  
  def initialize_koala
    @needs_to_link_account = false
    new_arrival = false
    need_to_check_user = false
    need_to_check_permissions = false
    
    @@oauth ||= Koala::Facebook::OAuth.new(
      Worlize.config['facebook']['app_id'],
      Worlize.config['facebook']['app_secret'],
      url_for(:controller => 'facebook_canvas', :action => 'auth_callback')
    )
    @@app_api ||= Koala::Facebook::API.new(@@oauth.get_app_access_token)
    
    if params[:signed_request].nil?
      @signed_request = session[:signed_request]
    else
      @signed_request = @@oauth.parse_signed_request(params[:signed_request])
      session[:signed_request] = @signed_request
      need_to_check_user = true
      need_to_check_permissions = true
    end
    
    if current_user.nil?
      need_to_check_user = true
    end
    
    if need_to_check_user
      check_user
    end
    
    if @signed_request.nil? || @signed_request['user_id'].nil?
      redirect_to_auth_page
    else
      @user_api = Koala::Facebook::API.new(@signed_request['oauth_token'])
      
      # Make sure we have all the requested permissions before continuing.
      if need_to_check_permissions && !verify_permissions
        redirect_to_auth_page
      end
    end
    
    
  end
  
  def redirect_to_auth_page
    # With the new Authenticated Referrals system, all users will be logged
    # in by the time they get to our canvas page.
    # render :text => 'No usable signed_request available.', :status => 400 and return

    # For now, we have to redirect to the permissions dialog
    redirect_url = @@oauth.url_for_oauth_code(
      :permissions => Worlize.config['facebook']['requested_permissions']
    )
    
    render(
      :text => "<script>top.location.href='#{escape_javascript(redirect_url)}';</script>",
      :content_type => 'text/html'
    )
  end

  def check_user
    return if @signed_request.nil?
    @needs_to_link_account = false
    if @signed_request['user_id']
      authentication = Authentication.where(
        :provider => 'facebook',
        :uid => @signed_request['user_id']
      ).first

      # Check to see if a Worlize user is already logged in.
      if current_user
        if authentication.nil?
          if current_user.facebook_authentication.nil?
            # Logged in Worlize user isn't linked to any facebook account
            # Prompt user to link their account
            @needs_to_link_account = true
            
          else
            # Logged in Worlize user is linked to another facebook
            # account, and the current facebook account isn't linked
            # to any Worlize account.  Log out the current Worlize user.
            UserSession.find.destroy
            reset_current_user
          end
          
        elsif authentication.user_id != current_user.id
          # A Worlize user is logged in that is not the one linked to the
          # current Facebook account.  We'll need to log them out to
          # proceed.  Then we'll log in the correct Worlize user.
          UserSession.find.destroy
          reset_current_user
          authentication.update_attribute(:token, @signed_request['oauth_token'])
          UserSession.create(authentication.user)
        
        elsif authentication.user_id == current_user.id
          # This facebook account is linked to the current Worlize user.
        end

      elsif authentication
        # No worlize user logged in, but we have an authentication.
        # Log in the current facebook user.
        authentication.update_attribute(:token, @signed_request['oauth_token'])
        reset_current_user
        UserSession.create(authentication.user)
      end

    end
  end
  
  def verify_permissions
    Rails.logger.debug("Verifying user permissions")
    @permissions = @user_api.get_connections('me', 'permissions')
    if @permissions.empty?
      return false
    end
    requested_permissions = Worlize.config['facebook']['requested_permissions'].split(',')
    requested_permissions.each do |perm|
      return false unless @permissions[0][perm]
    end
    return true
  end

  def signed_request
    @signed_request
  end
  
  def oauth
    @@oauth
  end
  
  def app_api
    @@app_api
  end
  
  def user_api
    @user_api
  end
end
