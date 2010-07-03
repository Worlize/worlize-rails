class Room < ActiveRecord::Base
  before_create :assign_guid
  
  belongs_to :world

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
end
