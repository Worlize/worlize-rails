class UsersController < ApplicationController
  before_filter :require_user, :except => [:create]
  
  def create
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:invite_code])
    @user = User.new(params[:user])
    @user.inviter = @beta_invitation.inviter
    if @user.save
      if (@beta_invitation)
        @beta_invitation.destroy
      end
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
    @user = User.find_by_guid(params[:id])
    respond_to do |format|
      
      if @user != current_user
        @object = @user.public_hash_for_api
      else
        @object = @user.hash_for_api
      end
      
      format.json do
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
