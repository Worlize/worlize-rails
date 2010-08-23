class Avatar < ActiveRecord::Base
  has_many :avatar_instances, :dependent => :destroy
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  
  mount_uploader :image, AvatarUploader
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :small =>         self.image.small.url,
      :tiny =>          self.image.tiny.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url,
      :return_coins =>  self.return_coins
    }
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
