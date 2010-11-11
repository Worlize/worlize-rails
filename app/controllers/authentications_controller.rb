class AuthenticationsController < ApplicationController
  # GET /authentications
  # GET /authentications.xml
  
  before_filter :require_user, :except => [ :create, :failure ]
  
  def index
    @authentications = current_user.authentications if current_user

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @authentications }
      format.json { render :json => @authentications }
    end
  end

  # GET /authentications/1
  # GET /authentications/1.xml
  def show
    @authentication = current_user.authentications.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @authentication }
      format.json { render :json => @authentication }
    end
  end

  def failure
    flash[:error] = "Your authentication was unsuccessful."
    respond_to do |format|
      format.html { redirect_to current_user ? profile_authentications_url : root_url }
    end
  end

  # POST /authentications
  # POST /authentications.xml
  def create
    omniauth = request.env["omniauth.auth"]
    logger.debug "Authentication Details:\n#{omniauth.to_yaml}\n"
    
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    flash[:notice] = "Authentication Successful"
    if authentication
      UserSession.create(authentication.user)
    elsif current_user
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
    else
      user = User.new
      if omniauth['provider'] == 'twitter'
        user.name = omniauth['user_info']['name']
        user.username = omniauth['user_info']['nickname']
      end
      user.admin = true
      user.name = omniauth['']
      user.authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
      user.save(:validate => false)
      UserSession.create(authentication.user)
    end
    redirect_to root_url
  end

  # DELETE /authentications/1
  # DELETE /authentications/1.xml
  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to(profile_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
end
