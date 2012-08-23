class ModeratorsController < ApplicationController
  before_filter :require_user
  
  def index
    world = World.find_by_guid!(params[:world_id])
    
    permissions = current_user.applied_permissions(world.guid)
    has_permission = permissions.include?('can_access_moderation_dialog')
    
    if !has_permission
      render :json => {
        :success => false,
        :message => "Permission denied"
      } and return
    end
    
    moderators = world.moderators.map do |user|
      world_permissions = user.permissions(world.guid, false)
      global_permissions = user.permissions
      applied_permissions = world_permissions | global_permissions
      
      user.public_hash_for_api.merge({
        :permissions => {
          :world => world_permissions,
          :global => global_permissions,
          :applied => applied_permissions
        }
      })
    end
    
    result = {
      :success => true,
      :moderators => moderators
    }
    
    render :json => result
  end
  
  def update
    world = World.find_by_guid!(params[:world_id])
    @user = User.find_by_guid!(params[:moderator_id])
    
    permissions = params[:permissions] ? params[:permissions] : {}
    @user.set_permissions(permissions.keys, world.guid)
    
    render :json => {
      :success => true
    }
  end
end
