class UsersController < ApplicationController
  before_filter :require_user, :except => [:new, :create, :validate_field, :birthday, :set_birthday]
  before_filter :require_user_without_storing_location, :only => [:birthday, :set_birthday]

  layout 'bootstrap'

  def new
    if current_user
      redirect_to dashboard_url and return
    end

    @user = User.new(:newsletter_optin => true)
    
    # Pre-fill as much information as we can from an omniauth login
    oa = session[:omniauth]
    if oa && oa['info']
      @provider = oa['provider']
      if oa['provider'] == 'facebook'
        @user.first_name = oa['info']['first_name']
        @user.last_name = oa['info']['last_name']
        @user.username = oa['info']['nickname']
        @user.login_name = oa['info']['nickname']
        @user.email = oa['info']['email']
        @email_autofilled = true
      elsif oa['provider'] == 'twitter'
        @user.username = oa['info']['nickname']
        @email_autofilled = false
      end
      @require_password = false
      @user.skip_password_requirement = true
      @user.valid?
      @user.errors.delete(:accepted_tos)
    else
      @require_password = true
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
          redirect_to enter_room_url(@user.main_world_entrance.guid)
        end
      end
      format.json do
        render :json => {
          :success => true,
          :online => @user.online?,
          :room_guid => @user.online? ? @user.current_room_guid : @user.main_world_entrance.guid
        }
      end
    end
  end

  def create
    if params[:user] && params[:user][:password].blank?
      params[:user].delete(:password) and params[:user].delete(:password_confirmation)
    end
    
    @user = User.new(params[:user])
    if session[:omniauth]
      # Password not explicitly required if using social login
      @user.skip_password_requirement = true
      
      if session[:omniauth]['provider'] == 'facebook'
        @user.birthday = session[:omniauth]['info']['birthday']
      end
    end
    

    if !@user.save
      if session[:omniauth]
        @provider = session[:omniauth]['provider']
        if session[:omniauth]['provider'] == 'facebook'
          @email_autofilled = true
        end
        @require_password = false
      else
        @email_authofilled = false
        @require_password = true
      end
      render "users/new" and return
    end
    
    @user.first_time_login
    @user.create_world

    if session[:omniauth]
      # Make sure to link the external account!
      Rails.logger.debug("Omniauth:\n#{session[:omniauth].to_yaml}") if Rails.env == 'development'
      omniauth = session[:omniauth]

      create_options = {
        :provider => omniauth['provider'],
        :uid => omniauth['uid'],
        :token => omniauth['credentials']['token'],
        :profile_picture => omniauth['info']['image']
      }

      if omniauth['provider'] == 'facebook'
        create_options[:profile_url] = omniauth['info']['urls']['Facebook']
        @user.interactivity_session.update_attributes(
          :facebook_id => omniauth['uid']
        )
      elsif omniauth['provider'] == 'twitter'
        create_options[:profile_url] = omniauth['info']['urls']['Twitter']
      end

      success = @user.authentications.create(create_options)

      if !success
        flash[:alert] = "Unable to associate your #{omniauth['provider'].capitalize} account."
      end
      session.delete(:omniauth)
    end
    
    if @user.newsletter_optin
      @user.add_to_mailchimp
    end

    redirect_back_or_default dashboard_url
  end

  def show
    if params[:id].nil?
      @user = current_user
    else
      begin
        @user = User.find_by_guid(Guid.from_s(params[:id]).to_s)
      rescue ArgumentError
        @user = User.find_by_username!(params[:id])
      end
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
  
  def birthday
    @user = current_user
    render :layout => 'bootstrap'
  end
  
  def set_birthday
    @user = current_user

    unless params[:verify_age_checkbox] == 'true'
      @user.errors.add(:birthday, "must be confirmed by checking the box to indicate that you are 13 years of age or older.")
      render :birthday, :layout => 'bootstrap' and return
    end
    
    success = @user.update_attributes(params[:user])
    
    if success
      redirect_back_or_default(root_url)
    else
      render :birthday, :layout => 'bootstrap'
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
  
  def change_password
    current_user.password = params[:password]
    current_user.password_changed_at = Time.now
    if current_user.save
      render :json => {
        :success => true,
        :password_changed_at => current_user.password_changed_at
      }
    else
      render :json => {
        :success => false,
        :message => current_user.errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
      }
    end
  end
  
  def settings
    begin
      data = Yajl::Parser.parse(params[:data])
    rescue
      render :json => {
        :success => false,
        :message => "Invalid JSON data provided"
      }, :status => 400
      return
    end
    
    success = current_user.update_attributes(data['user'])
    # Record audit log items
    current_user.previous_changes.each_pair do |key,changes|
      unless ['perishable_token','updated_at'].include?(key)
        Worlize.audit_logger.info("action=user_field_changed_by_user user=#{current_user.guid} user_username=\"#{current_user.username}\" field_name=#{key} old_value=\"#{changes[0]}\" new_value=\"#{changes[1]}\"")
      end
    end
    
    if success
      render :json => {
        :success => true,
        :user => current_user.hash_for_api
      }
    else
      render :json => {
        :success => false,
        :message => current_user.errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
      }
    end
  end
  
  def check_username_availability
    u = User.new(:username => params[:username])
    u.valid?
      
    respond_to do |format|
      format.json do
        render :json => {
          :success => !u.errors.include?(:username),
          :username => params[:username]
        }
      end
    end
  end

end
