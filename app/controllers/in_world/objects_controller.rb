class InWorld::ObjectsController < ApplicationController

  def create
    x = params[:x] || 0
    y = params[:y] || 0
    dest = params[:dest] if params[:dest] && params[:dest].length == 36
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    world = current_user.worlds.first
    room = world.rooms.find_by_guid(params[:room_id])
    oi = current_user.in_world_object_instances.find_by_guid(params[:id])
    if oi && room
      
      if oi.room
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "This object is already in use in room #{oi.room.guid}"
        }) and return
      end
      
      oi.update_attribute(:room, room)
      
      begin
        rd = Yajl::Parser.parse(redis.hget('roomDefinition', room.guid))
        object_definition = {
          :guid => oi.guid,
          :object => oi.in_world_object.guid,
          :pos => [x,y]
        }
        object_definition[:dest] = dest if dest
        (rd['object_instances'] ||= []) << object_definition
        
        redis.hset('roomDefinition', room.guid, Yajl::Encoder.encode(rd))
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => e
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => e.message
        }) and return
      end
    end
    
    render :json => Yajl::Encoder.encode({
      :success => false
    })
  end
  
  def update
    x = params[:x]
    y = params[:y]
    dest = params[:dest] if params[:dest] && params[:dest].length == 36
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)

    oi_guid = params[:id]    
    world = current_user.worlds.first
    room = world.rooms.find_by_guid(params[:room_id])
    if room && oi_guid
    
      begin
        rd = Yajl::Parser.parse(redis.hget('roomDefinition', room.guid))
        object_instances = rd['object_instances'] || []
      
        object_instances.each do |instance|
          if instance['guid'] == oi_guid
            instance['x'] = x if x
            instance['y'] = y if y
            if dest
              instance['dest'] = dest
            else
              instance.delete('dest')
            end
            break
          end
        end
      
        redis.hset('roomDefinition', room.guid, Yajl::Encoder.encode(rd))
        Worlize::PubSub.publish(
          "room:#{self.guid}",
          '{"msg":"room_definition_updated"}'
        )
      
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => e
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => e.message
        }) and return
      end
      
    render :json => Yajl::Encoder.encode({
      :success => false
    })
  end
  
  def destroy
    world = current_user.worlds.first
    room = world.rooms.find_by_guid(params[:room_id])
    oi_guid = params[:id]
    oi = InWorldObjectInstance.find_by_guid(oi_guid)
    if room && oi
      
      oi.update_attribute(:room, nil)
      
      begin
        rd = Yajl::Parser.parse(redis.hget('roomDefinition', room.guid))
        object_instances = rd['object_instances'] || []
      
        object_instances.delete_if do |instance|
          instance['guid'] == oi_guid
        end
      
        redis.hset('roomDefinition', room.guid, Yajl::Encoder.encode(rd))
        Worlize::PubSub.publish(
          "room:#{self.guid}",
          '{"msg":"room_definition_updated"}'
        )
      
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      rescue => e
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => e.message
        }) and return
      end
    end
    render :json => Yajl::Encoder.encode({
      :success => false,
      :description => "You do not own the room specified or it cannot be found"
    })
  end

end
