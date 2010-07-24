class Room < ActiveRecord::Base
  belongs_to :world
  has_one :background_instance
  has_many :in_world_object_instances
  
  before_create :assign_guid
  after_save :update_room_definition
  
  def update_room_definition
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    
    begin
      rd = Yajl::Parser.parse(redis.hget('roomDefinition', self.guid) || '{}')
      
      rd['name'] = self.name
      rd['world_guid'] = self.world.guid
      
      bi = self.background_instance
      rd['background'] = bi ? bi.background.image.url : 'http://www.worlize.com/images/default_room_background.jpg'
      unless rd['object_instances']
        rd['object_instances'] = self.in_world_object_instances.map do |oi|
          {
            'guid' => oi.guid,
            'object' => oi.in_world_object.guid,
            'pos' => [ 200, 200 ]
          }
        end
      end
      rd['hotspots'] ||= []
      
      redis.hset('roomDefinition', self.guid, Yajl::Encoder.encode(rd))
      
      unless redis.hget('propsInRoom', self.guid)
        redis.hset('propsInRoom', self.guid, '[]')
      end
      
      Worlize::PubSub.publish(
        "room:#{self.guid}",
        '{"msg":"room_definition_updated"}'
      )
            
    rescue => e
      e.message << ': failed while updating room definition'
      raise e
    end
    
    
  end
  
  # before_create :create_room_definition
  # before_update :update_room_definition
  # after_destroy :destroy_room_definition
  
end
