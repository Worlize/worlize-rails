class FacebookCanvasController < ApplicationController

  include ActionView::Helpers::JavaScriptHelper

  layout 'facebook_canvas'
  
  skip_before_filter :verify_authenticity_token
  
  before_filter  :log_headers, :set_p3p

  def index
    signed_request = oauth.parse_signed_request(params[:signed_request])
    
    if !signed_request['user_id']
      oauth_url = oauth.url_for_oauth_code(
        :permissions => Worlize.config['facebook']['requested_permissions'],
        :callback => request.url
      )
      quoted_redirect_url = escape_javascript(oauth_url)
      render(
        :text => "<script>top.location.href='#{quoted_redirect_url}';</script>",
        :content_type => 'text/html'
      ) and return
    end
    
    session[:signed_request] = signed_request
    if params[:request_ids]
      session[:request_ids] = params[:request_ids]
    end

    # request_ids = params[:request_ids]
    # if params[:request_ids]
    #   request_ids = params[:request_ids].split(',')
    #   if request_ids.length == 1
    #     redirect_to :action => :handle_request, :id => request_ids.first and return
    #   end
    # end
    
    fb_api = Koala::Facebook::API.new(oauth.get_app_access_token)
    @app_requests = fb_api.get_connections(signed_request['user_id'], 'apprequests')
    @app_requests.each do |fb_request|
      if fb_request['data']
        begin
          fb_request['data'] = Yajl::Parser.parse(fb_request['data'])
        rescue
        end
      end
    end
  end

  def handle_request
    fb_api = Koala::Facebook::API.new(oauth.get_app_access_token)
    @request = fb_api.get_object(params[:id])
    if @request && @request['data']
      begin
        @request['data'] = Yajl::Parser.parse(@request['data'])
      rescue
      end
    end

    if @request['data'] && @request['data']['action'] == 'join'
      session[:return_to] = join_user_url(@request['data']['inviter_guid'])
    else
      session[:return_to] = dashboard_url
    end

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
  
  def oauth
    @oauth ||= Koala::Facebook::OAuth.new(Worlize.config['facebook']['app_id'], Worlize.config['facebook']['app_secret'])
  end
  
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
end
