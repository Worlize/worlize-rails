class Admin::PermissionsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  def show
    @user = User.find(params[:user_id])
    @permissions = @user.permissions
  end
  
  def update
    @user = User.find(params[:user_id])
    
    permissions = params[:permissions] ? params[:permissions] : {}
    @user.set_permissions(permissions.keys)
    flash[:notice] = "Permissions saved successfully."
    redirect_to admin_user_permissions_url(@user)
  end
  
end