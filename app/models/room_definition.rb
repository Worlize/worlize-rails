class RoomDefinition < RedisModel
  redis_server :room_definitions
  redis_hash_key 'roomDefinition'
  schema_version 1
  
  initialize_attributes(
    :guid,
    :world_guid,
    :name,
    :background,
    :object_instances
  )
  
  define_method 'background', lambda {
    attributes['background'] || Worlize.config['default_room_background_url']
  }
  
  after_update :broadcast_update_notification
  
  validates :guid, :presence => true
  validates :background, :presence => true
  
  def hash_for_api
    serializable_hash.merge({
      :hotspots => self.hotspots
    })
  end
  
  def initialize(attributes = {})
    super
    room_object = attributes[:room] || attributes['room']
    self.room = room_object unless room_object.nil?
    self.object_instances = [] if self.object_instances.nil?
  end
  
  def room
    @room ||= Room.find_by_guid(self.guid)
  end
  
  def hotspots
    hotspots_raw = redis.hget('hotspots', self.guid)
    begin
      Yajl::Parser.parse(hotspots_raw)
    rescue
      []
    end
  end
  
  def hotspots=(new_array)
    begin
      redis.hset('hotspots', self.guid, Yajl::Encoder.encode(new_array))
    rescue
    end
  end
  
  def room=(room)
    @room = room
    self.guid = room.guid
    self.world_guid = room.world.guid
    self.name = room.name
    self.background = room.background_instance.nil? ? nil : room.background_instance.background.image.url
  end
  
  def broadcast_update_notification
    Worlize::PubSub.publish(
      "room:#{self.guid}",
      '{"msg":"room_definition_updated"}'
    )
  end
  
end

