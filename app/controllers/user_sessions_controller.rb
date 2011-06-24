class UserSessionsController < ApplicationController

  before_filter :require_user, :only => [:vanilla_sso]

  # GET /user_sessions
  # GET /user_sessions.xml
  
  # GET /user_sessions/new
  # GET /user_sessions/new.xml
  def new
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
    rescue
    end

    respond_to do |format|
      format.html { redirect_to(root_url) }
    end
  end
  
  def vanilla_sso
    render :text =>
      "UniqueID=#{current_user.id}\n" +
      "Name=#{current_user.username}\n" +
      "Email=#{current_user.email}\n" +
      "DateOfBirth=#{current_user.birthday.strftime('%Y-%m-%d')}"
  end
end
