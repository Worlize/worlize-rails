class RestrictionsController < ApplicationController
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
    
    active_restrictions = world.user_restrictions.active
    
    render :json => {
      :success => true,
      :restrictions => active_restrictions.map { |ur| ur.hash_for_api }
    }
  end
  
  def create
    target_user = User.find_by_guid!(params[:user_id])

    # Check for an existing active restriction that matches.
    ur = UserRestriction.active.limit(1).where(
      :user_id => target_user.id,
      :name => params[:name],
      :global => params[:global]
    )
    if params[:world_guid]
      world = World.find_by_guid!(params[:world_guid])
      ur = ur.where(:world_id => world.id)
      
      # Make sure that no one can be banned from their own world
      if world.user.id == target_user.id && params[:name] == 'ban'
        render :json => {
          :success => false,
          :errors => [
            'You cannot ban a user from their own world.'
          ]
        }
        return
      end
    end
    ur = ur.first
    
    if !ur.nil?
      # If one is already in effect, update it instead of creating a new one.
      new_attrs = { :updated_by => current_user }
      new_attrs[:expires_at] = params[:minutes].to_i.minutes.from_now if params.include?(:minutes)
      new_attrs[:reason] = params[:reason] if params.include?(:reason)
      success = ur.update_attributes(new_attrs) 
    else
      # Otherwise create a new restriction
      options = {
        :user => target_user,
        :name => params[:name],
        :global => params[:global],
        :created_by => current_user,
        :updated_by => current_user,
        :expires_at => params[:minutes].to_i.minutes.from_now,
        :reason => params[:reason]
      }
      
      options[:world] = world if params[:world_guid]

      if (options[:expires_at] > Time.now)
        ur = UserRestriction.create(options)
        success = ur.valid? && !ur.new_record?
      else
        success = true
      end
    end
    
    if success
      render :json => { :success => true }
    else
      render :json => {
        :success => false,
        :errors => ur.errors.full_messages
      }
    end
  end
end
