class Admin::UserRestrictionsController < ApplicationController
  layout 'admin'
  
  before_filter :require_global_moderator_permission
  
  def index
    @restrictions = UserRestriction.active.global.order('`user_restrictions`.`updated_at` DESC')

    # Apply pagination
    @restrictions = @restrictions.paginate(:page => params[:page], :per_page => 50)
  end
  
  def show
    @restriction = UserRestriction.find(params[:id])
  end
  
  def destroy
    @restriction = UserRestriction.find(params[:id])
    if @restriction
      @success = @restriction.update_attributes(
        :expires_at => Time.now,
        :updated_by => current_user
      )
      if !@success
        flash[:error] = "Unable to lift the requested restriction."
      end
    end
    redirect_to admin_user_restrictions_url
  end
end
