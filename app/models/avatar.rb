class Avatar < ActiveRecord::Base
  has_many :avatar_instances
  belongs_to :creator, :class_name => 'User'
  
  before_create :assign_guid
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
