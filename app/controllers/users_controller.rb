class UsersController < ApplicationController
  
  def create
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:invite_code])
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Registration Successful."
      if (@beta_invitation)
        @beta_invitation.destroy
      end
      @user.first_time_login
      redirect_to profile_authentications_url
    else
      render "invitations/show"
    end
  end

  def show
    @user = User.find(params[:id])
  end

end
