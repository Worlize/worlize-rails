class UsersController < ApplicationController
  before_filter :require_user, :except => [:new, :create, :validate_field]

  layout 'login'

  def new
    if current_user
      redirect_to dashboard_url and return
    end

    @user = User.new
    
    # Pre-fill as much information as we can from an omniauth login
    oa = session[:omniauth]
    if oa && oa['user_info']
      if oa['provider'] == 'facebook'
        @user.first_name = oa['user_info']['first_name']
        @user.last_name = oa['user_info']['last_name']
        @user.username = oa['user_info']['nickname']
        @user.email = oa['user_info']['email']
        @email_autofilled = true
      elsif oa['provider'] == 'twitter'
        @user.username = oa['user_info']['nickname']
        @email_autofilled = false
      end
    end
    
  end
  
  def index
    redirect_to root_url
  end

  def validate_field
    attribute = params[:field_name]
    value = params[:value]
    
    if !attribute.nil? && !value.nil?
      mock = User.new(attribute => value)
      mock.valid?
      
      response = {}
      response[:valid] = mock.errors[attribute.to_sym].empty?
      if (!response[:valid])
        message = mock.errors[attribute.to_sym].first
        response[:field_name] = attribute
        response[:value] = params[:value]
        response[:message] = message
        response[:full_message] = "#{attribute.capitalize} #{message}"
      end

      render :json => response
    else
      render :json => {
        :valid => false,
        :message => "You must specify an attribute name and a value"
      }
    end
  end

  def join
    begin
      @user = User.find_by_guid(Guid.from_s(params[:id]).to_s)
    rescue ArgumentError
      @user = User.find_by_username!(params[:id])
    end
    
    respond_to do |format|
      format.html do
        if @user.online?
          redirect_to enter_room_url(@user.current_room_guid)
        else
          redirect_to enter_room_url(@user.worlds.first.rooms.first.guid)
        end
      end
      format.json do
        render :json => {
          :success => true,
          :online => @user.online?,
          :room_guid => @user.online? ? @user.current_room_guid : @user.worlds.first.rooms.first.guid
        }
      end
    end
  end

  def create
    if !session[:omniauth]
      redirect_to new_user_url and return
    end

    @beta_invitation = BetaInvitation.find_by_invite_code(params[:invite_code])

    @user = User.new(params[:user])
    if session[:omniauth]['provider'] == 'facebook'
      @user.birthday = session[:omniauth]['user_info']['birthday']
    end
    if @beta_invitation
      @user.inviter = @beta_invitation.inviter
    end

    if @user.save
      if @beta_invitation
        @beta_invitation.destroy
      end
      @user.first_time_login
      @user.create_world
      if @user.inviter
        @user.befriend(@user.inviter)
      end
      
      # Make sure to link the external account!
      Rails.logger.debug("Omniauth:\n#{session[:omniauth].to_yaml}") if Rails.env == 'development'
      omniauth = session[:omniauth]
      
      create_options = {
        :provider => omniauth['provider'],
        :uid => omniauth['uid'],
        :token => omniauth['credentials']['token'],
        :profile_picture => omniauth['user_info']['image']
      }
      
      if omniauth['provider'] == 'facebook'
        create_options[:profile_url] = omniauth['user_info']['urls']['Facebook']
      elsif omniauth['provider'] == 'twitter'
        create_options[:profile_url] = omniauth['user_info']['urls']['Twitter']
      end
      
      success = @user.authentications.create(create_options)
      
      @user.add_to_mailchimp

      if !success
        flash[:alert] = "Unable to associate your #{omniauth['provider'].capitalize} account."
      end
      session.delete(:omniauth)
      
      redirect_back_or_default dashboard_url
    else
      @email_autofilled = (session[:omniauth]['provider'] == 'facebook')
      render "users/new"
    end
  end

  def show
    begin
      @user = User.find_by_guid(Guid.from_s(params[:id]).to_s)
    rescue ArgumentError
      @user = User.find_by_username!(params[:id])
    end
    
    respond_to do |format|
      format.html do
        @world = @user.worlds.first
        @entrance = @world.rooms.first
        @background_thumb = @entrance.background_instance.background.image.medium.url
      end
      format.json do
        if !@user.nil?
          if @user != current_user
            @object = @user.public_hash_for_api
          else
            @object = @user.hash_for_api
          end
        end
        render :json => {
          :success => true,
          :data => @object
        }
      end
    end
  end
  
  def search
    if params[:q].nil?
      render :json => {
        :success => true,
        :count => 0,
        :data => {}
      } and return
    end

    search_term = params[:q].split(/\s/).first
    if search_term.empty?
      render :json => {
        :success => true,
        :count => 0,
        :data => {}
      } and return
    end
    
    # Don't let users insert their own wildcards
    search_term.gsub!('%', '')
    
    query = User.where('username LIKE ? OR email = ?', "#{search_term}%", search_term)
    query = query.where('id != ?', current_user.id)
    results = query.limit(10).order('username ASC').all
    render :json => {
      :success => true,
      :total => query.count,
      :count => results.length,
      :data => results.map do |user|
        {
          :guid => user.guid,
          :username => user.username,
          :is_friend => current_user.is_friends_with?(user),
          :has_pending_request => current_user.has_requested_friendship_of?(user)
        }
      end
    }
  end

end
