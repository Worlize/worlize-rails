class World < ActiveRecord::Base
  belongs_to :user
  has_many :rooms, :order => 'position, id', :dependent => :destroy
  has_one :public_world, :dependent => :destroy
  has_one :permalink, :as => :linkable, :dependent => :destroy
  has_many :user_restrictions

  before_create :assign_guid
  before_destroy :check_destroy_preconditions
  after_update :notify_users_of_changes
  
  RATINGS = {
    'Not Rated' => {
      :min_age => 13
    },
    'All Ages' => {
      :min_age => 13
    },
    '18+' => {
      :min_age => 18
    },
    '21+' => {
      :min_age => 21
    }
  }
  
  validates :name, :presence => true
  # validates :rating, :inclusion => { :in => RATINGS.keys }
  
  attr_accessible :name

  def basic_hash_for_api
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api,
      :permalink => self.permalink ? self.permalink.link : nil
    }
  end

  def hash_for_api(current_user=nil)
    basic_hash_for_api.merge({
      :can_create_new_room => current_user == self.user,
      :rooms => self.rooms.map do |room|
        room.basic_hash_for_api(current_user)
      end
    })
  end
  
  def can_be_edited_by?(user)
    owner = self.user
    return user == owner
  end
  
  def connected_user_guids
    user_guids = []
    self.rooms.each do |room|
      user_guids.concat(room.connected_user_guids)
    end
    user_guids.uniq!
    user_guids
  end
  
  def user_list
    user_guids = Array.new
    rooms_by_user_guid = Hash.new
    
    self.rooms.each do |room|
      room_user_guids = room.connected_user_guids
      user_guids.concat(room_user_guids)
      room_user_guids.each do |user_guid|
        rooms_by_user_guid[user_guid] = room
      end
    end
    user_guids.uniq!
    
    User.where(:guid => user_guids).order('username ASC').map do |user|
      room = rooms_by_user_guid[user.guid]
      {
        :room_guid => room.guid,
        :room_name => room.name,
        :username => user.username,
        :user_guid => user.guid
      }
    end
  end
  
  def population
    user_guids = Array.new
    self.rooms.each do |room|
      room_user_guids = room.connected_user_guids
      user_guids.concat(room_user_guids)
    end
    user_guids.uniq!
    user_guids.length
  end
  
  def rebuild_from_template_world(template)
    old_rooms = self.rooms.clone
    
    new_rooms = add_rooms_from_template_world(template)
    new_dest_guid = new_rooms.first.guid
    
    old_rooms.each do |room|
      # Move everyone to the new first room in the world
      Worlize::InteractServerManager.instance.broadcast_to_room(room.guid, {
        :msg => 'goto_room',
        :data => new_dest_guid
      })
      room.destroy
    end
    nil
  end
  
  def add_rooms_from_template_world(template)
    new_rooms = []
    
    # We need to iterate through the rooms multiple times to create the
    # new room copies and populate the hotspots and objects
    room_data = template.rooms.map do |room|
      data = {
        :original_room => room
      }
    end

    # To wire up the destinations for hotspots and objects we need a mapping
    # from the original template world room guids to the new room guids
    room_guid_map = {}
    
    room_data.each do |data|
      original_room = data[:original_room]
      # Create the new room
      new_room = self.rooms.create(
        :name => original_room.name,
        :hidden => original_room.hidden
      )
      
      room_guid_map[original_room.guid] = new_room.guid

      if original_room.background_instance
        background = original_room.background_instance.background
      
        # Find an available instance of the background image in the user's locker
        background_instance = self.user.background_instances.where([
          'background_id = ? AND room_id IS NULL', background.id
        ]).limit(1).first
      
        # ...or create one if the user doesn't have an available background instance
        if background_instance.nil?
          background_instance = self.user.background_instances.create(
            :background => background
          )
        end
      
        # Link the background instance to the new room
        background_instance.room = new_room
        background_instance.save
      end
      
      data[:new_room] = new_room
      new_rooms.push(new_room)
    end
    
    # Now that we have the base rooms created, we can start creating the
    # user's object and app instances and then call to the node servers to
    # clone the room definition.
    room_data.each do |data|
      item_guid_map = {}
      
      data[:original_room].in_world_object_instances.each do |original_object_instance|
        in_world_object = original_object_instance.in_world_object

        # Find an available instance of the object in the user's locker...
        object_instance = self.user.in_world_object_instances.where([
          'in_world_object_id = ? AND room_id IS NULL', in_world_object.id
        ]).limit(1).first
        
        # ...or create one if the user doesn't have an available object
        if object_instance.nil?
          object_instance = self.user.in_world_object_instances.create(
            :in_world_object => in_world_object
          )
        end
        
        object_instance.room = data[:new_room]
        object_instance.save
        
        item_guid_map[original_object_instance.guid] = object_instance.guid
      end
      
      data[:original_room].app_instances.each do |original_app_instance|
        app = original_app_instance.app

        # Find an available instance of the app in the user's locker...
        app_instance = self.user.app_instances.where([
          'app_id = ? AND room_id IS NULL', app.id
        ]).limit(1).first
        
        # ...or create one if the user doesn't have an available object
        if app_instance.nil?
          app_instance = self.user.app_instances.create(
            :app => app
          )
        end
        
        app_instance.room = data[:new_room]
        app_instance.save
        
        item_guid_map[original_app_instance.guid] = app_instance.guid
      end
      
      clone_result = RoomDefinition.clone(
        data[:original_room].guid,
        data[:new_room].guid,
        room_guid_map,
        item_guid_map
      )
      
      if !clone_result
        Rails.logger.error("Unable to clone room definition.")
      end
    end

    new_rooms
  end
  
  def self.initial_template_world_guid
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.get 'initial_world_guid'
  end
  
  def self.initial_template_world_guid=(guid)
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.set 'initial_world_guid', guid
  end

  def notify_users_of_changes
    Worlize::InteractServerManager.instance.broadcast_to_world(self.guid, {
      :msg => 'world_definition',
      :data => {
        :world => basic_hash_for_api
      }
    })
  end
  
  def user_is_moderator?(user)
    user = User.find_by_guid(user) unless user.is_a?(User)
    return true if moderator_guids.include?(user.guid)
    global_moderation_permission = Worlize::PermissionLookup.normalize_to_permission_id('can_moderate_globally')
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    return redis.sismember("g:#{user.guid}", global_moderation_permission)
  end
  
  def moderator_guids
    return @moderator_guids unless @moderator_guids.nil?
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    @moderator_guids = redis.zrange("wml:#{guid}", 0, -1)
    @moderator_guids.push(self.user.guid) unless @moderator_guids.include?(self.user.guid)
    return @moderator_guids
  end
  
  def moderators
    return User.where(:guid => moderator_guids).all.select { |u| !u.nil? }
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def check_destroy_preconditions
    return false if World.initial_template_world_guid == self.guid
  end
  
end
