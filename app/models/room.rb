class Room < ActiveRecord::Base
  belongs_to :world
  has_one :background_instance
  has_many :in_world_object_instances
  
  before_create :assign_guid
  after_save :update_room_definition
  after_destroy :delete_room_definition
  
  def room_definition
    @rd ||= (RoomDefinition.find(self.guid) || RoomDefinition.new(:room => self))
  end

  def can_be_edited_by?(user)
    true
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
