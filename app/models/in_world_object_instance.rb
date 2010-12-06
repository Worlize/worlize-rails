class InWorldObjectInstance < ActiveRecord::Base
  belongs_to :in_world_object
  belongs_to :user
  belongs_to :room
  
  before_create :assign_guid
  
  def hash_for_api
    {
      :in_world_object => self.in_world_object.hash_for_api,
      :room => self.room ? self.room.basic_hash_for_api : nil,
      :guid => self.guid
    }
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
