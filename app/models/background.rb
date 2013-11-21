class Background < ActiveRecord::Base
  has_many :background_instances, :dependent => :destroy
  has_many :users, :through => :background_instances
  has_many :gifts, :as => :giftable
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  before_create :log_creation
  after_destroy :log_destruction
  has_one :image_fingerprint, :as => :fingerprintable

  mount_uploader :image, BackgroundUploader

  validates :image,
              :presence => true

  def self.initial_world_background_guid
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.get 'initial_world_background_guid'
  end
  
  def self.initial_world_background_guid=(guid)
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.set 'initial_world_background_guid', guid
  end

  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url
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
    self.background_instances
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def log_creation
    Worlize.event_logger.info("action=background_created user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=background_destroyed user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end

end



# class BackgroundImageAsset < ActiveRecord::Base
#   has_attached_file :image,
#                     :styles => { :fullsize => "900x540#", :medium => "275x165#", :thumbnail => "133x80#" },
#                     :storage => :s3,
#                     :s3_credentials => "#{Rails.root}/config/s3.yml",
#                     :path => ":id/:style.:extension",
#                     :bucket => "worlize_backgrounds_dev"
#                     
# end
