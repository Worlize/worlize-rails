class InWorldObject < ActiveRecord::Base
  has_many :in_world_object_instances, :dependent => :destroy
  has_many :users, :through => :in_world_object_instances
  belongs_to :creator, :class_name => 'User'
  
  mount_uploader :image, InWorldObjectUploader
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url,
      :return_coins =>  self.return_coins
    }
  end
  
  before_create :assign_guid
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
