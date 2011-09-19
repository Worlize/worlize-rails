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
      format.html { redirect_to current_user ? dashboard_url : root_url }
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
      Rails.logger.debug "User already logged in, linking additional authentication."
      if authentication
        flash[:alert] = "That #{omniauth['provider'].capitalize} account has already been associated with a Worlize account."
      else
        create_options = {
          :provider => omniauth['provider'],
          :uid => omniauth['uid'],
          :token => omniauth['credentials']['token']
        }
        
        if omniauth['provider'] == 'facebook'
          create_options[:profile_url] = omniauth['user_info']['urls']['Facebook']
        elsif omniauth['provider'] == 'twitter'
          create_options[:profile_url] = omniauth['user_info']['urls']['Twitter']
        end
        
        success = current_user.authentications.create(create_options)
        if !success
          flash[:alert] = "Unable to associate your #{omniauth['provider'].capitalize} account."
        end
      end
      redirect_to dashboard_url

    # If we don't have a currently logged in user, we log in as the user we
    # found when we looked up the external provider credentials.
    elsif authentication
      Rails.logger.debug "Found a matching authentication record, logging user in"
      
      if omniauth['credentials'] && omniauth['credentials']['token']
        authentication.token = omniauth['credentials']['token']
      end
      if omniauth['provider'] == 'facebook'
        authentication.profile_url = omniauth['user_info']['urls']['Facebook']
      elsif omniauth['provider'] == 'twitter'
        authentication.profile_url = omniauth['user_info']['urls']['Twitter']
      end
      authentication.save
      
      UserSession.create(authentication.user)
      redirect_back_or_default dashboard_url

    # If we couldn't find an existing linked account and there isn't a
    # currently logged in user, we will start the signup process
    else
      Rails.logger.debug "Unable to find matching omniauth authentication"
      session[:omniauth] = omniauth.except('extra')
      redirect_to new_user_url
    end
  end
  
  def connect_facebook_via_js
    fb_authentication = current_user.authentications.where(:provider => 'facebook').first
    if fb_authentication
      render :json => {
        'success' => true,
        'detail' => 'Account already connected'
      } and return
    end
    
    # Koala API methods will raise errors for things like expired tokens
    begin
      fb_graph = Koala::Facebook::API.new(params[:access_token])
      # Get user's list of facebook friends
      fb_profile = fb_graph.get_object('me')
    rescue Koala::Facebook::APIError => e
      render :json => {
        'success' => false,
        'error' => e.to_s
      } and return
    end
    
    if fb_profile['id']
      fb_authentication = current_user.authentications.create(
        :provider => 'facebook',
        :uid => fb_profile['id'],
        :token => params[:access_token]
      )
      render :json => {
        'success' => fb_authentication.persisted?
      }
    else
      render :json => {
        'success' => false,
        'detail' => 'Unable to get facebook user id'
      }
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
