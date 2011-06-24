class AuthenticationsController < ApplicationController
  # GET /authentications
  # GET /authentications.xml
  
  before_filter :require_user, :except => [ :create, :failure ]
  
  def index
    @authentications = current_user.authentications if current_user

    @facebook_connected = current_user.authentications.where(:provider => 'facebook').count > 0
    @twitter_connected = current_user.authentications.where(:provider => 'twitter').count > 0

    @can_continue = @facebook_connected || @twitter_connected

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
      format.html { redirect_to current_user ? dashboard_authentications_url : root_url }
    end
  end

  # POST /authentications
  # POST /authentications.xml
  def create
    omniauth = request.env["omniauth.auth"]
    if Rails.env == 'development'
      logger.debug "Authentication Details:\n#{omniauth.to_yaml}\n"
    end
    
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    # If we already have a user logged in, then we assume we're
    # simply associating their external account
    if current_user
      if authentication
        flash[:alert] = "That #{omniauth['provider'].capitalize} account has already been associated with a Worlize account."
      else
        success = current_user.authentications.create(:provider => omniauth['provider'], :uid => omniauth['uid'])
        if !success
          flash[:alert] = "Unable to associate your #{omniauth['provider'].capitalize} account."
        end
      end
      redirect_to dashboard_authentications_url

    # If we don't have a currently logged in user, we log in as the user we
    # found when we looked up the external provider credentials.
    elsif authentication
      UserSession.create(authentication.user)
      redirect_to session[:return_to] || root_url
      session[:return_to] = nil

    # If we couldn't find an existing linked account and there isn't a
    # currently logged in user, we will start the signup process
    else
      session[:omniauth] = omniauth.except('extra')
      redirect_to new_user_url
    end
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
