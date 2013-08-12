class Locker::InWorldObjectsController < ApplicationController
  before_filter :require_user

  def index
    result = current_user.in_world_object_instances.includes(:in_world_object, :room => :world).order('created_at DESC')
    result = result.map do |o|
      o.hash_for_api
    end
    
    render :json => {
      :success => true,
      :capacity => current_user.in_world_object_slots,
      :count => result.length,
      :data => result
    }
  end
  
  def create
    name = params[:name] || "Object by #{current_user.username}"
    
    @in_world_object = InWorldObject.new(
      :name => name,
      :creator => current_user,
      :requires_approval => false,
      :image => params[:filedata]
    )
    
    if @in_world_object.save
      oi = current_user.in_world_object_instances.create(:in_world_object => @in_world_object)
      if (oi.persisted?)
        render :json => {
          :success => true,
          :data => oi.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "Unable to create in-world object instance."
        }
      end
    else
      render :json => {
        :success => false,
        :description => "In-world object is invalid.",
        :errors => @in_world_object.errors
      }
    end
  end
  
  def destroy
    instance = current_user.in_world_object_instances.find_by_guid(params[:id])
    
    if instance.room
      # must yank it from the room where its currently used
      instance.room.room_definition.remove_item(instance.guid)
    end
    
    num_instances_remaining = instance.in_world_object.in_world_object_instances.count
    if num_instances_remaining == 1 && instance.in_world_object.marketplace_item.nil?
      instance.in_world_object.destroy
    else
      instance.destroy
    end

    render :json => {
      :success => instance.destroyed?,
      :balance => {
        :coins => current_user.coins,
        :bucks => current_user.bucks
      }
    }
  end
  
end
