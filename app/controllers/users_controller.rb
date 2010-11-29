class UsersController < ApplicationController
  
  def create
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:invite_code])
    @user = User.new(params[:user])
    if @user.save
      if (@beta_invitation)
        @beta_invitation.destroy
      end
      @user.first_time_login
      @user.create_world
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

end
