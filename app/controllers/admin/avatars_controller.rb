class Admin::AvatarsController < ApplicationController
  layout 'admin'
  before_filter :require_global_moderator_permission
  
  def index
    unless current_user.admin? || current_user.permissions.include?('can_view_admin_user_detail')
      flash[:error] = "You do not have permission to view user profiles."
      redirect_to admin_index_url and return
    end

    @user = User.find(params[:user_id])
    @avatars = @user.avatar_instances.includes(:avatar).map(&:avatar)
  end
  
  def show
    @user = User.find(params[:user_id])
    @avatar = Avatar.find_by_guid!(params[:id])
  end
  
  def destroy
    @user = User.find(params[:user_id])
    @avatar = Avatar.find_by_guid!(params[:id])
    @avatar.destroy
    redirect_to admin_user_avatars_url(@user)
  end
end
