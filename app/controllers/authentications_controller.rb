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
    session.delete(:popup_auth)
    flash[:error] = "Your authentication was unsuccessful."
    respond_to do |format|
      format.html { redirect_to current_user ? dashboard_url : root_url }
    end
  end
  
  def popup_auth
    session[:popup_auth] = Time.now
    redirect_to "/auth/#{params[:provider]}"
  end

  # POST /authentications
  # POST /authentications.xml
  def create
    popup_auth = session[:popup_auth] && session[:popup_auth] > 5.minutes.ago
    session.delete(:popup_auth)
    omniauth = request.env["omniauth.auth"]
    if Rails.env == 'development'
      Rails.logger.debug "Authentication Details:\n#{omniauth.to_yaml}\n"
      Rails.logger.debug "Session: \n#{session.to_yaml}\n"
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
          :token => omniauth['credentials']['token'],
          :display_name => omniauth['info']['name']
        }
        
        if omniauth['provider'] == 'facebook'
          create_options[:profile_url] = omniauth['info']['urls']['Facebook']
          current_user.interactivity_session.update_attributes(
            :facebook_id => omniauth['uid']
          )
        elsif omniauth['provider'] == 'twitter'
          create_options[:profile_url] = omniauth['info']['urls']['Twitter']
          create_options[:profile_picture] = omniauth['info']['image']
        end
        
        success = current_user.authentications.create(create_options)
        if !success
          flash[:alert] = "Unable to associate your #{omniauth['provider'].capitalize} account."
        end
      end
      
      if popup_auth
        render 'authentications/popup_auth', :layout => false and return
      else
        redirect_to dashboard_url
      end

    # If we don't have a currently logged in user, we log in as the user we
    # found when we looked up the external provider credentials.
    elsif authentication
      Rails.logger.debug "Found a matching authentication record, logging user in"

      # Omniauth seems to use an inefficient url for Facebook images that is
      # different from the URL we get when querying the graph api.  We don't
      # want to cache the Omniauth profile pic url because it will constantly
      # get changed back and forth when the one of the user's friends loads
      # their friends list and when the user logs in.
      if omniauth['provider'] != 'facebook'
        authentication.profile_picture = omniauth['info']['image']
      end
      authentication.display_name = omniauth['info']['name']
      if omniauth['credentials'] && omniauth['credentials']['token']
        authentication.token = omniauth['credentials']['token']
      end
      if omniauth['provider'] == 'facebook'
        authentication.profile_url = omniauth['info']['urls']['Facebook']
      elsif omniauth['provider'] == 'twitter'
        authentication.profile_url = omniauth['info']['urls']['Twitter']
      end
      authentication.save
      
      UserSession.create(authentication.user)
      redirect_back_or_default dashboard_url

    # If we couldn't find an existing linked account and there isn't a
    # currently logged in user, we will start the signup process
    else
      Rails.logger.debug "Unable to find matching omniauth authentication"
      if omniauth['provider'] == 'facebook'
        omniauth['info']['birthday'] = Date.strptime(omniauth['extra']['raw_info']['birthday'], '%m/%d/%Y')
      end
      session[:omniauth] = omniauth.except('extra')
      redirect_to new_user_url
    end
  end
  
  def connect_facebook_via_js
    fb_authentication = current_user.facebook_authentication
    
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
      fb_profile = fb_graph.get_object('me', {:fields => 'id,birthday,picture,link,name'})
      if Rails.env == 'development'
        Rails.logger.debug fb_profile.to_yaml
      end
    rescue Koala::Facebook::APIError => e
      render :json => {
        'success' => false,
        'error' => e.to_s
      } and return
    end
    
    if fb_profile['id']
      existing_authentication = Authentication.find(
        :provider => 'facebook',
        :uid => fb_profile['id']
      )
      unless existing_authentication.empty?
        render :json => {
          'success' => false,
          'detail' => 'Facebook account is already connected to a different Worlize account'
        } and return
      end
      
      fb_authentication ||= current_user.authentications.create
      fb_authentication.provider = 'facebook'
      fb_authentication.uid = fb_profile['id']
      fb_authentication.token = params[:access_token]
      fb_authentication.profile_url = fb_profile['link']
      fb_authentication.display_name = fb_profile['name']
      fb_authentication.profile_picture = fb_profile['picture']
      fb_authentication.save
      
      current_user.update_attribute(:birthday, fb_profile['birthday'])
      
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
    success = false
    
    @authentication = current_user.authentications.where(:provider => params[:id]).first
    if @authentication
      @authentication.destroy
      success = true
    end

    respond_to do |format|
      format.html { redirect_to(profile_url) }
      format.xml  { head :ok }
      format.json {
        render :json => {
          :success => success
        }
      }
    end
  end
end
