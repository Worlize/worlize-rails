class InWorld::ObjectsController < ApplicationController

  def create
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    in_world_object_instance = current_user.in_world_object_instances.find_by_guid(params[:in_world_object_instance_guid])

    if in_world_object_instance

      if in_world_object_instance.room
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "This object is already in use in room \"#{in_world_object_instance.room.name}\""
        }) and return
      end
      
      begin
        manager = room.room_definition.in_world_object_manager
        manager.add_object_instance(in_world_object_instance, params[:x], params[:y])
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => detail
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => detail.message
        }) and return
      end
    end
  end
  
  def update
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    in_world_object_instance = current_user.in_world_object_instances.find_by_guid(params[:id])
    
    if in_world_object_instance
      begin
        manager = room.room_definition.in_world_object_manager
        if params[:x] && params[:y]
          manager.move_object_instance(in_world_object_instance, params[:x], params[:y])
        elsif params[:dest]
          dest = (params[:dest] != 'null') ? params[:dest] : nil
          manager.update_object_destination(in_world_object_instance, dest)
        end
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => detail
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => detail.message
        }) and return
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Unable to find the specified object instance"
      }) and return
    end
  end
  
  def destroy
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    in_world_object_instance = current_user.in_world_object_instances.find_by_guid(params[:id])

    if in_world_object_instance
      begin
        manager = room.room_definition.in_world_object_manager
        manager.remove_object_instance(in_world_object_instance)
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => detail
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => detail.message
        }) and return
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You must provide an object instance guid"
      }) and return
    end
  end

end
