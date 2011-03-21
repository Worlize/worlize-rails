class InvitationsController < ApplicationController
  before_filter :require_user, :only => [ :create ]
  
  def show
    if current_user
      flash[:alert] = "You are already logged in as #{current_user.username}.  Please sign out before attempting to register a new account."
      redirect_to dashboard_url and return
    end
    @beta_invitation = BetaInvitation.find_by_invite_code!(params[:id])
    @user = User.new(
      :first_name => @beta_invitation.first_name,
      :last_name => @beta_invitation.last_name,
      :email => @beta_invitation.email
    )
  end
  
  def create
    invitation = BetaInvitation.create(
      :email => params[:email],
      :inviter => current_user
    )
    if invitation.persisted?
      email = InvitationNotifier.beta_invitation_email({
        :beta_invitation => invitation,
        :inviter => current_user,
        :account_creation_url => invite_url(invitation.invite_code)
      })
      email.deliver
      
      render :json => Yajl::Encoder.encode({
        :success => true,
        :remaining_invites => current_user.invites,
        :description => "#{invitation.email} has been invited."
      }) and return
    end
    
    render :json => Yajl::Encoder.encode({
      :success => false,
      :description => invitation.errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
    })
  end
end
