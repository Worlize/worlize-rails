class Prop < ActiveRecord::Base
  has_many :prop_instances, :dependent => :destroy
  has_many :users, :through => :prop_instances
  has_many :gifts, :as => :giftable, :dependent => :destroy
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  before_create :log_creation
  after_destroy :log_destruction
  
  mount_uploader :image, PropUploader

  validates :image,
              :presence => true
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :image =>         self.image.url,
      :thumbnail =>     self.image.thumb.url,
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
    self.prop_instances
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

  def log_creation
    Worlize.event_logger.info("action=prop_created user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=prop_destroyed user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end

end
