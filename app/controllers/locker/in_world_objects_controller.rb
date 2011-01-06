class Locker::InWorldObjectsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.in_world_object_instances.map do |o|
      o.hash_for_api
    end
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :capacity => current_user.in_world_object_slots,
      :count => result.length,
      :data => result
    })
  end
  
  def create
    name = params[:name] || "Object by #{current_user.username}"
    
    @in_world_object = InWorldObject.new(
      :name => name,
      :sale_coins => 0,
      :sale_bucks => 0,
      :return_coins => 0,
      :creator => current_user,
      :image => params[:filedata]
    )
    
    if @in_world_object.save
      oi = current_user.in_world_object_instances.create(:in_world_object => @in_world_object)
      if (oi.persisted?)
        render :json => Yajl::Encoder.encode({
          :success => true,
          :data => oi.hash_for_api
        })
      else
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "Unable to create in-world object instance."
        })
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "In-world object is invalid.",
        :errors => @in_world_object.errors
      })
    end
  end
  
  def destroy
    instance = current_user.in_world_object_instances.find_by_guid(params[:id])
    
    if instance.room
      # must yank it from the room where its currently used
      manager = instance.room.room_definition.in_world_object_manager
      manager.remove_object_instance(instance)
    end
    
    num_instances_remaining = instance.in_world_object.in_world_object_instances.count
    if num_instances_remaining == 1
      instance.in_world_object.destroy
    else
      instance.destroy
    end
    current_user.credit_account :coins => instance.in_world_object.return_coins

    render :json => Yajl::Encoder.encode({
      :success => instance.destroyed?,
      :balance => {
        :coins => current_user.coins,
        :bucks => current_user.bucks
      }
    })
  end
  
end