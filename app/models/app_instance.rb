class AppInstance < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
  belongs_to :room
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user
  before_destroy :remove_from_room
  
  def hash_for_api
    {
      :app => app.hash_for_api,
      :room => room ? {
        :name => room.name,
        :guid => room.guid,
        :world_guid => room.world.guid,
        :hidden => room.hidden
      } : nil,
      :guid => guid
    }
  end
  
  private
  def notify_user
    if self.user
      self.user.send_message({
        :msg => 'app_instance_added',
        :data => self.hash_for_api
      })
    end
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s if self.guid.nil?
  end
  
  def remove_from_room
    unless room.nil?
      room.room_definition.remove_item(ai.guid)
    end
    true
  end
  
end
