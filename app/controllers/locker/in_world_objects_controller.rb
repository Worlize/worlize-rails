class Locker::InWorldObjectsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.in_world_object_instances.includes(:in_world_object, :user).order('created_at DESC').map do |o|
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
    filename_parts = params[:filedata].original_filename.split('.');
    if filename_parts.last.downcase == 'swf'
      uploadSwf(params)
    else
      uploadImage(params)
    end
  end
  
  def destroy
    instance = current_user.in_world_object_instances.find_by_guid(params[:id])
    
    if instance.room
      # must yank it from the room where its currently used
      manager = instance.room.room_definition.in_world_object_manager
      begin
        manager.remove_object_instance(instance)
      rescue
        # do nothing
      end
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
  
  private
  
  def uploadImage(params)
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
  
  def uploadSwf(params)
    if !current_user.developer?
      render :json => {
        :success => false,
        :description => "Only developers can upload SWF objects."
      } and return
    end
    
    name = params[:name] || "Untitled App Object"
    
    @in_world_object = InWorldObject.new(
      :kind => 'app',
      :name => name,
      :creator => current_user,
      :width => params[:width],
      :height => params[:height],
      :app => params[:filedata],
      :requires_approval => true,
      :reviewal_status => 'new'
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
      Rails.logger.debug("Model errors:\n" + @in_world_object.errors.to_s)
      render :json => {
        :success => false,
        :description => "In-world object is invalid.",
        :errors => @in_world_object.errors
      }
    end
  end
  
end
