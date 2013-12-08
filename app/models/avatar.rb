class Avatar < ActiveRecord::Base
  has_many :avatar_instances, :dependent => :destroy
  has_many :users, :through => :avatar_instances
  has_many :gifts, :as => :giftable, :dependent => :destroy
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  before_create :log_creation
  after_destroy :log_destruction
  has_one :image_fingerprint, :as => :fingerprintable
  
  mount_uploader :image, AvatarUploader
  
  validates :image,
              :presence => true
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url,
      :creator_guid =>  self.creator.nil? ? nil : self.creator.guid,
      :animated_gif =>  self.animated_gif
    }
  end
  
  def hash_for_gift_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :animated_gif =>  self.animated_gif
    }
  end
  
  def instances
    self.avatar_instances
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def log_creation
    Worlize.event_logger.info("action=avatar_created user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=avatar_destroyed user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
end
