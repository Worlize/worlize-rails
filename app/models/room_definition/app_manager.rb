class RoomDefinition::AppManager
  attr_accessor :room_definition
  attr_accessor :raw_data
  
  def initialize(room_definition)
    self.room_definition = room_definition
    load
  end

  def load
    begin
      self.raw_data = Yajl::Parser.parse(redis.hget('apps', room_definition.guid))
    rescue
      self.raw_data = []
    end
    self
  end
  
  def save
    redis.hset('apps', room_definition.guid, Yajl::Encoder.encode(raw_data))
    self
  end
  
  def destroy
    redis.hdel('apps', room_definition.guid)
  end
  
  def add_app_instance(app_instance, x, y, dest=nil)
    if app_instance.room.nil?
      app_instance.update_attribute(:room, room_definition.room)
      app = app_instance.app
      app_definition = {
        'creator' => app.creator.guid,
        'name' => app.name,
        'guid' => app_instance.guid,
        'app_guid' => app.guid,
        'x' => x,
        'y' => y
      }
      
      app_definition['app_url'] = app.app.url
      app_definition['width'] = app.width
      app_definition['height'] = app.height
      app_definition['small_icon'] = app.icon.small.url
      app_definition['config'] = {}
      app_definition['test_mode'] = true
      
      raw_data << app_definition
      save
      Worlize::InteractServerManager.instance.broadcast_to_room(
        room_definition.guid,
        {
          :msg => 'new_app',
          :data => {
            :room => room_definition.guid,
            :app => app_definition
          }
        }
      )
    else
      raise Exception, "App is already used in a room"
    end
  end
  
  def move_app_instance(app_instance, x, y)
    raw_data.each do |app_data|
      if app_data['guid'] == app_instance.guid
        app_data['x'] = x
        app_data['y'] = y
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'app_moved',
            :data => {
              :room => room_definition.guid,
              :app => app_data
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified app instance guid"
  end
  
  def update_app_destination(app_instance, dest)
    raw_data.each do |app_data|
      if app_data['guid'] == app_instance.guid
        app_data['dest'] = dest
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'app_updated',
            :data => {
              :room => room_definition.guid,
              :app => app_data
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified app instance guid"
  end
  
  def remove_app_instance(app_instance)
    # unlink the room from the instance.
    app_instance.update_attribute(:room, nil)
    
    # Remove any app config data
    redis.hdel('app_config', app_instance.guid)

    # find instance in the list, remove it, and announce the change to the room
    raw_data.each_index do |i|
      if raw_data[i]['guid'] == app_instance.guid
        raw_data.delete_at i
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'app_removed',
            :data => {
              :room => room_definition.guid,
              :guid => app_instance.guid
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified app instance guid"
  end
  
  def unlink_all
    app_instances.each do |app_data|
      app_instance = AppInstance.find_by_guid(app_data['guid'])
      if !app_instance.nil?
        app_instance.update_attribute(:room, nil)
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'app_removed',
            :data => {
              :room => room_definition.guid,
              :guid => app_instance.guid
            }
          }
        )
      end
    end
    
  end
  
  def app_instances
    raw_data
  end

  private
  
  def redis
    Worlize::RedisConnectionPool.get_client(:room_definitions)
  end
  
end