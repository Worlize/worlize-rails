class RoomDefinition::InWorldObjectManager
  attr_accessor :room_definition
  attr_accessor :raw_data
  
  def initialize(room_definition)
    self.room_definition = room_definition
    load
  end

  def load
    begin
      self.raw_data = Yajl::Parser.parse(redis.hget('in_world_objects', room_definition.guid))
    rescue
      self.raw_data = []
    end
    self
  end
  
  def save
    redis.hset('in_world_objects', room_definition.guid, Yajl::Encoder.encode(raw_data))
    self
  end
  
  def destroy
    redis.hdel('in_world_objects', room_definition.guid)
  end
  
  def add_object_instance(in_world_object_instance, x, y, dest=nil)
    if in_world_object_instance.room.nil?
      in_world_object_instance.update_attribute(:room, room_definition.room)
      in_world_object = in_world_object_instance.in_world_object
      object_definition = {
        'kind' => in_world_object.kind,
        'guid' => in_world_object_instance.guid,
        'object_guid' => in_world_object.guid,
        'x' => x,
        'y' => y
      }
      
      if in_world_object.kind == 'app'
        object_definition['app_url'] = in_world_object.app.url
        object_definition['width'] = in_world_object.width
        object_definition['height'] = in_world_object.height
        object_definition['small_icon'] = in_world_object.icon.small.url
        if in_world_object.requires_approval && in_world_object.reviewal_status != 'accepted'
          object_definition['test_mode'] = true
        end
      elsif in_world_object.kind == 'image'
        object_definition['fullsize_url'] = in_world_object.image.url
        object_definition['dest'] = dest
      end
      
      require 'pp'
      pp object_definition
      
      raw_data << object_definition
      save
      Worlize::InteractServerManager.instance.broadcast_to_room(
        room_definition.guid,
        {
          :msg => 'new_object',
          :data => {
            :room => room_definition.guid,
            :object => object_definition
          }
        }
      )
    else
      raise Exception, "Object is already used in a room"
    end
  end
  
  def move_object_instance(in_world_object_instance, x, y)
    raw_data.each do |object_data|
      if object_data['guid'] == in_world_object_instance.guid
        object_data['x'] = x
        object_data['y'] = y
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'object_moved',
            :data => {
              :room => room_definition.guid,
              :object => object_data
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified object instance guid"
  end
  
  def update_object_destination(in_world_object_instance, dest)
    raw_data.each do |object_data|
      if object_data['guid'] == in_world_object_instance.guid
        object_data['dest'] = dest
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'object_updated',
            :data => {
              :room => room_definition.guid,
              :object => object_data
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified object instance guid"
  end
  
  def remove_object_instance(in_world_object_instance)
    # unlink the room from the instance.
    in_world_object_instance.update_attribute(:room, nil)

    # find instance in the list, remove it, and announce the change to the room
    raw_data.each_index do |i|
      if raw_data[i]['guid'] == in_world_object_instance.guid
        raw_data.delete_at i
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'object_removed',
            :data => {
              :room => room_definition.guid,
              :guid => in_world_object_instance.guid
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified object instance guid"
  end
  
  def unlink_all
    object_instances.each do |object_data|
      in_world_object_instance = InWorldObjectInstance.find_by_guid(object_data['guid'])
      if !in_world_object_instance.nil?
        in_world_object_instance.update_attribute(:room, nil)
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'object_removed',
            :data => {
              :room => room_definition.guid,
              :guid => in_world_object_instance.guid
            }
          }
        )
      end
    end
    
  end
  
  def object_instances
    raw_data
  end

  private
  
  def redis
    Worlize::RedisConnectionPool.get_client(:room_definitions)
  end
  
end