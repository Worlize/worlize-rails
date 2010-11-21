class InvitationsController < ApplicationController
  def show
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:id])
    @user = User.new(
      :first_name => @beta_invitation.first_name,
      :last_name => @beta_invitation.last_name,
      :email => @beta_invitation.email
    )
  end
end
