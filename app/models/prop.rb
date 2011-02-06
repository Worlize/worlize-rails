class Prop < ActiveRecord::Base
  has_many :prop_instances, :dependent => :destroy
  has_many :users, :through => :prop_instances
  has_many :gifts, :as => :giftable
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid
    }
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
