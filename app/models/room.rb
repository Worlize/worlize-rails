class Room < ActiveRecord::Base
  belongs_to :world
  has_one :background_instance, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :app_instances, :dependent => :nullify
  has_many :sharing_links, :dependent => :destroy
  
  has_one :permalink, :as => :linkable, :dependent => :destroy
  
  acts_as_list :scope => :world
  
  after_initialize :set_defaults
  before_create :assign_guid
  before_destroy :notify_user_of_items_removal
  after_create :notify_users_of_creation
  after_save :update_room_definition, :notify_users_of_changes
  after_destroy :delete_room_definition, :notify_users_of_deletion
  
  # no_direct_entry means the user has to enter the room via a hotspot.
  
  attr_accessible :name, :hidden, :no_direct_entry
  
  validates :max_occupancy, :numericality => { :greater_than_or_equal_to => 1,
                                               :less_than_or_equal_to    => 75 }
    
  def basic_hash_for_api(current_user=nil)
    data = {
      :name => name,
      :guid => guid,
      :user_count => user_count,
      :world_guid => world.guid,
      :hidden => hidden,
      :max_occupancy => max_occupancy,
      :no_direct_entry => no_direct_entry,
      :thumbnail => background_instance ? background_instance.background.image.thumb.url : nil
    }
    if current_user && current_user.can_edit?(self)
      data[:properties] = self.room_definition.properties
    end
    data
  end

  def hash_for_api(current_user)
    {
      :room_definition => self.room_definition.hash_for_api,
      :user_count => user_count,
      :can_author => world.user == current_user,
      :hidden => hidden,
      :max_occupancy => max_occupancy,
      :no_direct_entry => no_direct_entry,
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
    @rd ||= (RoomDefinition.find(self.guid) || RoomDefinition.create(self))
  end
  
  def locked?
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    redis.get("lock:#{self.guid}") == '1'
  end

  def can_be_edited_by?(user)
    owner = self.world.user
    return user.id == owner.id
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
  def set_defaults
    self.max_occupancy = 20 if self.max_occupancy.nil?
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end

  def update_room_definition
    if !new_record? && (name_changed? || hidden_changed?)
      room_definition.name = self.name
      room_definition.save
    end
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
  
  def notify_user_of_items_removal
    room_definition.items.each do |item|
      Worlize::InteractServerManager.instance.broadcast_to_room(guid, {
        :msg => 'remove_item',
        :data => {
            :room => guid,
            :guid => item['guid']
        }
      })
    end
  end
  
  # before_create :create_room_definition
  # before_update :update_room_definition
  # after_destroy :destroy_room_definition
  
end
