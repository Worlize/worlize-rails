class Room < ActiveRecord::Base
  belongs_to :world
  has_one :background_instance
  has_many :in_world_object_instances
  
  has_many :sharing_links, :dependent => :destroy
  
  before_create :assign_guid
  after_save :update_room_definition
  after_destroy :delete_room_definition
    
  def basic_hash_for_api
    {
      :name => name,
      :guid => guid
    }
  end
    
  def hash_for_api(current_user)
    {
      :room_definition => self.room_definition.hash_for_api,
      :user_count => user_count,
      :can_author => world.user == current_user
    }
  end
  
  def user_count
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    redis.scard "roomUsers:#{self.guid}"
  end
  
  def connected_user_guids
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    redis.smembers "roomUsers:#{self.guid}"
  end
    
  def interact_server_id
    Worlize::InteractServerManager.instance.server_for_room(self.guid)
  end
  
  def room_definition
    @rd ||= (RoomDefinition.find(self.guid) || RoomDefinition.new(:room => self))
  end

  def can_be_edited_by?(user)
    owner = self.world.user
    return user == owner
  end
  
  def build_xml(xml)
    rd = room_definition
    objs = rd.in_world_object_manager.object_instances
    youtube_players = rd.youtube_manager.youtube_players
    
    xml.room(:name => self.name) {
      xml.items {
        objs.each do |obj|
          attrs = {
            :src => obj['fullsize_url'],
            :x => obj['x'],
            :y => obj['y']
          }
          attrs['destination'] = obj['dest'] if obj['dest']
          xml.object(attrs)
        end
        rd.hotspots.each do |hotspot|
          attrs = {
            :x => hotspot['x'],
            :y => hotspot['y']
          }
          attrs['destination'] = hotspot['dest'] if hotspot['dest']
          xml.hotspot(attrs) {
            hotspot['points'].each do |point|
              xml.point(:x => point[0], :y => point[1])
            end
          }
        end
      }
    }
  end
    
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

  def update_room_definition
    room_definition.room = self
    room_definition.save
  end
  
  def delete_room_definition
    room_definition.destroy
  end
  
  # before_create :create_room_definition
  # before_update :update_room_definition
  # after_destroy :destroy_room_definition
  
end
