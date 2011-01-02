class Admin::BetaRegistrationsController < ApplicationController
  layout 'admin'
  before_filter :require_admin
    
  def index
    sort_clause = 'created_at DESC'
    if params[:sort] == 'name'
      sort_clause = 'name ASC'
    end
    @registrations = Registration.paginate(:page => params[:page], :order => sort_clause)
  end
  
  def destroy
    @registration = Registration.find(params[:id])
    if @registration
      @registration.destroy
      @success = true
    else
      @success = false
      @message = "Unable to delete beta registration."
    end
    
    respond_to do |format|
      format.js
    end
    
  end
  
  def invite_user
    begin
      @registration = Registration.find(params[:id])
    rescue
      flash[:error] = "Unable to locate that beta registration"
      redirect_to admin_beta_registrations_url and return
    end

    @beta_invitation = BetaInvitation.create(
      :name => @registration.name,
      :first_name => @registration.first_name,
      :last_name => @registration.last_name,
      :email => @registration.email
    )
    
    @success = @beta_invitation.persisted?
    
    if @success
      email = InvitationNotifier.beta_accepted_email({
        :beta_invitation => @beta_invitation,
        :account_creation_url => invite_url(@beta_invitation.invite_code)
      })
      email.deliver
      
      @registration.destroy
    end
    
    respond_to do |format|
      format.js
    end
  end
  
end
