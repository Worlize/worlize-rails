class InWorldObject < ActiveRecord::Base
  has_many :in_world_object_instances, :dependent => :destroy
  has_many :users, :through => :in_world_object_instances
  belongs_to :creator, :class_name => 'User'
  
  before_create :assign_guid
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
