class World < ActiveRecord::Base
  before_create :assign_guid
  before_destroy :check_destroy_preconditions

  belongs_to :user
  has_many :rooms, :dependent => :destroy
  has_one :public_world, :dependent => :destroy
  
  validates :name, :presence => true

  def basic_hash_for_api
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api
    }
  end

  def hash_for_api(current_user=nil)
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api,
      :can_create_new_room => current_user == self.user,
      :rooms => self.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => room.user_count
        }
      end
    }
  end
  
  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.world(:name => self.name) {
        self.rooms.each do |room|
          room.build_xml(xml)
        end
      }
    end
    builder.to_xml
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
    
    users = user_guids.map do |user_guid|
      User.find_by_guid(user_guid)
    end
    users.reject! { |user| user.nil? }
    users.map do |user|
      room = rooms_by_user_guid[user.guid]
      {
        :room_guid => room.guid,
        :room_name => room.name,
        :user_name => user.username,
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
        :name => original_room.name
      )
      
      room_guid_map[original_room.guid] = new_room.guid
      
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
      
      # Set the background url in the room definition
      new_room.background_instance = background_instance
      new_room.room_definition.background = background.image.url
      new_room.save
      
      data[:new_room] = new_room
      new_rooms.push(new_room)
    end
    
    # Now that we have the base rooms created, we can start creating the
    # hotspots, objects, and YouTube players and wiring them up.
    room_data.each do |data|

      # Clone the hotspots...
      hotspots = data[:original_room].room_definition.hotspots

      hotspots.each do |hs|
        if hs['dest']
          hs['dest'] = room_guid_map[hs['dest']]
        end
      end
      
      # Save hotspots to redis
      data[:new_room].room_definition.hotspots = hotspots
    
      
      # Now to tackle objects...
      original_objects = data[:original_room].room_definition.in_world_object_manager.object_instances
      object_manager = data[:new_room].room_definition.in_world_object_manager
      object_instance_guid_map = {}
      
      original_objects.each do |obj_data|
        original_object_instance = InWorldObjectInstance.find_by_guid(obj_data['guid'])
        next unless original_object_instance # just in case something's broken
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
        
        object_manager.add_object_instance(
          object_instance,
          obj_data['x'],
          obj_data['y'],
          room_guid_map[obj_data['dest']]
        )
      end
      
      # And finally, YouTube Players.
      youtube_players = data[:original_room].room_definition.youtube_manager.youtube_players
      youtube_manager = data[:new_room].room_definition.youtube_manager
      
      youtube_players.each do |player_data|
        new_player = youtube_manager.create_new_player
        youtube_manager.move_player(
          new_player['guid'],
          player_data['x'],
          player_data['y'],
          player_data['width'],
          player_data['height']
        )
        youtube_manager.update_player_data(
          new_player['guid'],
          player_data['data']
        )
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

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def check_destroy_preconditions
    return false if World.initial_template_world_guid == self.guid
  end
end
