class InWorldObjectInstance < ActiveRecord::Base
  belongs_to :in_world_object
  belongs_to :user
  belongs_to :room
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user
  
  def hash_for_api
    {
      :in_world_object => self.in_world_object.hash_for_api,
      :room => room ? {
        :name => room.name,
        :guid => room.guid,
        :world_guid => room.world.guid,
        :hidden => room.hidden
      } : nil,
      :guid => self.guid
    }
  end
  
  private
  def notify_user
    if self.user
      self.user.send_message({
        :msg => 'in_world_object_instance_added',
        :data => self.hash_for_api
      })
    end
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
