class Avatar < ActiveRecord::Base
  has_many :avatar_instances, :dependent => :destroy
  has_many :users, :through => :avatar_instances
  has_many :gifts, :as => :giftable, :dependent => :destroy
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  
  mount_uploader :image, AvatarUploader
  
  validates :image,
              :presence => true
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :small =>         self.image.small.url,
      :tiny =>          self.image.tiny.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url,
      :creator_guid =>  self.creator.nil? ? nil : self.creator.guid
    }
  end
  
  def hash_for_gift_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url
    }
  end
  
  def instances
    self.avatar_instances
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
