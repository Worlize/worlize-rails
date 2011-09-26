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

    if !@request_ids.nil? && @request_ids.length > 1
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
      render 'display_requests' and return
    elsif !@request_ids.nil? && @request_ids.length == 1
      # only one request specified to handle, just do it.
      @request_id_to_handle = @request_ids.first
      handle_request and return
    end
  end
  
  def auth_callback
    if params[:error]
      redirect_to root_url
    else
      redirect_to "https://apps.facebook.com/#{Worlize.config['facebook']['app_name']}/"
    end
  end

  def handle_request
    # If we're called by another action, @request_id_to_handle will be
    # pre-populated by the caller.
    @request_id_to_handle ||= params[:id]

    @request_to_handle = user_api.get_object(@request_id_to_handle)
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
      session[:return_to] = join_user_url(data['inviter_guid'])
    else
      session[:return_to] = dashboard_url
    end

    # make sure we authenticate with the current user.
    log_user_out
    dest_url = "#{request.scheme}://#{request.host_with_port}/auth/facebook"
    render :text => '<script>top.location.href="' + escape_javascript(dest_url) + '"</script>',
           :content_type => 'text/html'
  end

  def ignore_request
    fb_api = Koala::Facebook::API.new(oauth.get_app_access_token)
    fb_api.delete_object(params[:id])
    render :nothing => true
  end

  private
  
  def log_user_out
    @user_session = UserSession.find()
    begin
      @user_session.destroy
      
      # Log the user out of the forums also
      cookies["Vanilla"] = {:value => "", :domain => ".worlize.com"}
      cookies["Vanilla-Volatile"] = {:value => "", :domain => ".worlize.com"}
    rescue
    end
  end

  def log_headers
    # Rails.logger.debug "Headers:"
    # request.headers.each_pair do |k,v|
    #   Rails.logger.debug "#{k.slice(5..k.length)} - #{v}" if k.index('HTTP_') == 0
    # end
    Rails.logger.debug "Session:\n#{session.to_yaml}"
  end

  def set_p3p
    response.headers["P3P"]='CP="CAO PSA OUR"'
  end
  
  def initialize_koala
    @@oauth ||= Koala::Facebook::OAuth.new(
      Worlize.config['facebook']['app_id'],
      Worlize.config['facebook']['app_secret'],
      url_for(:controller => 'facebook_canvas', :action => 'auth_callback')
    )
    @@app_api ||= Koala::Facebook::API.new(@@oauth.get_app_access_token)
    
    if params[:signed_request]
      @signed_request = @@oauth.parse_signed_request(params[:signed_request])
      session[:signed_request] = @signed_request
    else
      @signed_request = session[:signed_request]
    end

    if @signed_request.nil? || @signed_request['user_id'].nil?
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
      return
    end
    
    @user_api = Koala::Facebook::API.new(@signed_request['oauth_token'])
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
