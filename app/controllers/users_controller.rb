class UsersController < ApplicationController
  before_filter :require_user, :except => [:create]

  def new
    
  end

  def validate_field
    attribute = params[:field_name]
    value = params[:value]
    mock = User.new(attribute => value)

    response = {}
    response[:valid] = !mock.valid? && mock.errors[attribute.to_sym].empty?
    if (!response[:valid])
      message = mock.errors[attribute.to_sym].first
      response[:field_name] = attribute
      response[:value] = params[:value]
      response[:message] = message
      response[:full_message] = "#{attribute.capitalize} #{message}"
    end
    
    render :json => Yajl::Encoder.encode(response)
  end

  def create
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:invite_code])
    @user = User.new(params[:user])
    @user.inviter = @beta_invitation.inviter
    @user.beta_code = @beta_invitation.beta_code
    if @user.save
      if @beta_invitation.beta_code
        @beta_invitation.beta_code.consume
        JessicaNotifier.beta_code_signup(@user).deliver
      end
      @beta_invitation.destroy
      @user.first_time_login
      @user.create_world
      if @user.inviter
        @user.befriend(@user.inviter)
      end
      redirect_to dashboard_authentications_url
    else
      render "invitations/show"
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
        render :json => Yajl::Encoder.encode({
          :success => true,
          :data => @object
        })
      end
    end
  end
  
  def search
    if params[:q].nil?
      render :json => Yajl::Encoder.encode({
        :success => true,
        :count => 0,
        :data => {}
      }) and return
    end

    search_term = params[:q].split(/\s/).first
    if search_term.empty?
      render :json => Yajl::Encoder.encode({
        :success => true,
        :count => 0,
        :data => {}
      }) and return
    end
    
    # Don't let users insert their own wildcards
    search_term.gsub!('%', '')
    
    query = User.where('username LIKE ? OR email = ?', "#{search_term}%", search_term)
    query = query.where('id != ?', current_user.id)
    results = query.limit(10).order('username ASC').all
    render :json => Yajl::Encoder.encode({
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
    })
  end

end
