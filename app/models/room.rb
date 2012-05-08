class Room < ActiveRecord::Base
  belongs_to :world
  has_one :background_instance, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :app_instances, :dependent => :nullify
  has_many :sharing_links, :dependent => :destroy
  
  has_one :permalink, :as => :linkable, :dependent => :destroy
  
  acts_as_list :scope => :world
  
  before_create :assign_guid
  after_create :notify_users_of_creation
  after_save [:update_room_definition, :notify_users_of_changes]
  after_destroy [:delete_room_definition, :notify_users_of_deletion]
  
  attr_accessible :name, :hidden
    
  def basic_hash_for_api
    {
      :name => name,
      :guid => guid,
      :user_count => user_count,
      :world_guid => world.guid,
      :hidden => hidden,
      :properties => self.room_definition.properties,
      :thumbnail => background_instance ? background_instance.background.image.thumb.url : nil
    }
  end

  def hash_for_api(current_user)
    {
      :room_definition => self.room_definition.hash_for_api,
      :user_count => user_count,
      :can_author => world.user == current_user,
      :hidden => hidden,
      :thumbnail => background_instance ? background_instance.background.image.thumb.url : nil,
      :world_guid => world.guid,
      :guid => guid
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
  
  def locked?
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    redis.get("lock:#{self.guid}") == '1'
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
  
  def self.gate_room_guid=(guid)
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.set 'gate_room_guid', guid
  end
  
  def self.gate_room_guid
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.get 'gate_room_guid'
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

  def notify_users_of_creation
    Worlize::InteractServerManager.instance.broadcast_to_world(world.guid, {
      :msg => 'room_created',
      :data => basic_hash_for_api
    })
  end
  
  def notify_users_of_deletion
    Worlize::InteractServerManager.instance.broadcast_to_world(world.guid, {
      :msg => 'room_destroyed',
      :data => {
        :name => name,
        :guid => guid,
        :world_guid => world.guid
      }
    })
  end
  
  def notify_users_of_changes
    Worlize::InteractServerManager.instance.broadcast_to_world(world.guid, {
      :msg => 'room_updated',
      :data => basic_hash_for_api
    })
  end
  
  # before_create :create_room_definition
  # before_update :update_room_definition
  # after_destroy :destroy_room_definition
  
end
