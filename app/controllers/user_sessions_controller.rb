class UserSessionsController < ApplicationController
  layout 'login'
  
  def new
    if params[:redirect_to]
      session[:return_to] = params[:redirect_to]
    end
    
    if Rails.env == 'development'
      Rails.logger.debug "Cookies:\n" + cookies.to_yaml
      Rails.logger.debug "Session:\n" + session.to_yaml
    end
    
    @user_session = UserSession.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /user_sessions
  # POST /user_sessions.xml
  def create
    if Rails.env == 'development'
      Rails.logger.debug "Cookies:\n" + cookies.to_yaml
      Rails.logger.debug "Session:\n" + session.to_yaml
    end
    
    @user_session = UserSession.new(params[:user_session])

    respond_to do |format|
      if @user_session.save
        @user_session.user.reset_appearance!
        
        # Make sure any stale forum logins are cleared
        cookies["Vanilla"] = {:value => "", :domain => ".worlize.com"}
        cookies["Vanilla-Volatile"] = {:value => "", :domain => ".worlize.com"}

        default_url = enter_room_url(@user_session.user.worlds.first.rooms.first.guid)

        format.html { redirect_back_or_default(default_url) }
        format.json do
          render :json => {
            :success => true,
            :redirect_to => get_redirect_back_or_default_url(default_url)
          }
        end
      else
        format.html { render :action => "new" }
        format.json do
          render :json => {
            :success => false
          }
        end
      end
    end
  end

  # DELETE /user_sessions/1
  # DELETE /user_sessions/1.xml
  def destroy
    @user_session = UserSession.find()
    begin
      @user_session.destroy
      
      # Log the user out of the forums also
      cookies["Vanilla"] = {:value => "", :domain => ".worlize.com"}
      cookies["Vanilla-Volatile"] = {:value => "", :domain => ".worlize.com"}
    rescue
    end

    respond_to do |format|
      format.html { redirect_to(root_url) }
    end
  end
  
  def vanilla_sso
    if current_user
      render :text =>
          "UniqueID=#{current_user.id}\n" +
          "Name=#{current_user.username}\n" +
          "Email=#{current_user.email}",
        :content_type => 'text/plain'
    else
      render :text => '', :content_type => 'text/plain'
    end
  end
end
