class RoomDefinition < RedisModel
  redis_server :room_definitions
  redis_hash_key 'roomDefinition'
  schema_version 1
  
  initialize_attributes(
    :guid,
    :world_guid,
    :name,
    :background,
    :properties,
    :owner_guid
  )
  
  define_method 'background', lambda {
    attributes['background'] || Worlize.config['default_room_background_url']
  }
  
  after_update :broadcast_update_notification
  before_destroy :remove_dependent_objects
  
  validates :guid, :presence => true
  validates :background, :presence => true
  
  def hash_for_api
    serializable_hash.merge({
      :hotspots => self.hotspots,
      :objects => self.in_world_object_manager.object_instances,
      :youtube_players => self.youtube_manager.youtube_players,
      :properties => self.properties
    })
  end
  
  def initialize(attributes = {})
    super
    room_object = attributes[:room] || attributes['room']
    self.properties ||= {}
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
  
  def in_world_object_manager
    @in_world_object_manager ||= RoomDefinition::InWorldObjectManager.new(self)
  end
  
  def youtube_manager
    @youtube_manager ||= RoomDefinition::EmbeddedYoutubeManager.new(self)
  end
  
  def room=(room)
    @room = room
    self.guid = room.guid
    self.world_guid = room.world.guid
    self.owner_guid = room.world.user.guid
    self.name = room.name
    self.background = room.background_instance.nil? ? nil : room.background_instance.background.image.url
  end
  
  def update_property(name, value)
    self.properties[name] = value
  end
  
  def broadcast_update_notification
    Worlize::PubSub.publish(
      "room:#{self.guid}",
      '{"msg":"room_definition_updated"}'
    )
  end
  
  def remove_dependent_objects
    in_world_object_manager.unlink_all
    in_world_object_manager.destroy
    youtube_manager.destroy
  end
  
end

