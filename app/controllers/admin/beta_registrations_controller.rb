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
  
  def build_account
    begin
      @registration = Registration.find(params[:id])
    rescue
      flash[:error] = "Unable to locate that registration"
      redirect_to admin_beta_registrations_url and return
    end
    
    @user = User.new
    @user.name = @registration.name
    @user.email = @registration.email
    @user.twitter = @registration.twitter
    
  end
end
