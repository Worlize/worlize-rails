class UserSessionsController < ApplicationController
  layout 'admin'
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
        format.html { redirect_back_or_default(root_url) }
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
end
