class FacebookCanvasController < ApplicationController

  include ActionView::Helpers::JavaScriptHelper

  layout 'facebook_canvas'
  
  before_filter  :set_p3p

  def index
    request = oauth.parse_signed_request(params[:signed_request])
    session[:request] = request

    request_ids = params[:request_ids]
    if params[:request_ids]
      request_ids = params[:request_ids].split(',')
      if request_ids.length == 1
        redirect_to :action => :handle_request, :id => request_ids.first and return
      end
    end
    
    if !request['oauth_token']
      # render 'new_user' and return
    end
    
    fb_api = Koala::Facebook::API.new(oauth.get_app_access_token)
    @app_requests = fb_api.get_connections(request['user_id'], 'apprequests')
    @app_requests.each do |request|
      if request['data']
        begin
          request['data'] = Yajl::Parser.parse(request['data'])
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

  def set_p3p
    response.headers["P3P"]='CP="CAO PSA OUR"'
  end
end
