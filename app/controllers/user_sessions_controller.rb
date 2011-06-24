class UserSessionsController < ApplicationController
  # GET /user_sessions
  # GET /user_sessions.xml
  
  # GET /user_sessions/new
  # GET /user_sessions/new.xml
  def new
    if params[:redirect_to]
      session[:return_to] = params[:redirect_to]
    end
    
    @user_session = UserSession.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /user_sessions
  # POST /user_sessions.xml
  def create
    @user_session = UserSession.new(params[:user_session])

    respond_to do |format|
      if @user_session.save
        @user_session.user.reset_appearance!
        
        # Make sure any stale forum logins are cleared
        cookies["Vanilla"] = {:value => "", :domain => ".worlize.com"}
        cookies["Vanilla-Volatile"] = {:value => "", :domain => ".worlize.com"}

        if @user_session.user.linking_external_accounts?
          default_url = dashboard_authentications_url
        else
          default_url = dashboard_url
        end

        format.html { redirect_back_or_default(default_url) }
      else
        format.html { render :action => "new" }
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
          "Email=#{current_user.email}\n" +
          "DateOfBirth=#{current_user.birthday.strftime('%Y-%m-%d')}",
        :content_type => 'text/plain'
    else
      render :text => '', :content_type => 'text/plain'
    end
  end
end
