class Admin::BetaRegistrationsController < ApplicationController
  layout 'admin'
  before_filter :require_admin
    
  def index
    @registrations = Registration.paginate(:page => params[:page], :order => 'created_at DESC', :per_page => 10)
  end
  
  def build_account
    @registration = Registration.find(params[:id])
    flash[:notice] = "Found registration for #{@registration.name}"
    redirect_to admin_beta_registrations_url
  end
end
