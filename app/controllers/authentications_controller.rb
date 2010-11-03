class AuthenticationsController < ApplicationController
  # GET /authentications
  # GET /authentications.xml
  
  layout "admin"
  def index
    @authentications = current_user.authentications if current_user

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @authentications }
    end
  end

  # GET /authentications/1
  # GET /authentications/1.xml
  def show
    @authentication = Authentication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @authentication }
    end
  end

  # GET /authentications/new
  # GET /authentications/new.xml
  def new
    @authentication = Authentication.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @authentication }
    end
  end

  # GET /authentications/1/edit
  def edit
    @authentication = Authentication.find(params[:id])
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
    redirect_to admin_index_url
  end

  # PUT /authentications/1
  # PUT /authentications/1.xml
  def update
    @authentication = Authentication.find(params[:id])

    respond_to do |format|
      if @authentication.update_attributes(params[:authentication])
        format.html { redirect_to(@authentication, :notice => 'Authentication was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @authentication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /authentications/1
  # DELETE /authentications/1.xml
  def destroy
    @authentication = Authentication.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to(authentications_url) }
      format.xml  { head :ok }
    end
  end
end
