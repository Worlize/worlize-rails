class Room < ActiveRecord::Base
  before_create :assign_guid
  before_create :create_room_definition
  before_update :update_room_definition
  after_destroy :destroy_room_definition
  
  belongs_to :world

  def room_definition
    puts "Finding room definition for guid #{self.guid}"
    @rdef ||= RoomDefinition.find(self.guid)
    if @rdef.nil?
      create_room_definition
    end
    @rdef
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def create_room_definition
    @rdef = RoomDefinition.create(
      :guid => self.guid,
      :world_guid => self.world.guid,
      :name => self.name
    )
  end
  
  def update_room_definition
    self.room_definition.name = self.name
    self.room_definition.save
  end
  
  def destroy_room_definition
    self.room_definition.destroy
  end
end
