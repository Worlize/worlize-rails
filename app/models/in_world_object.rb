class InWorldObject < ActiveRecord::Base
  has_many :in_world_object_instances, :dependent => :destroy
  has_many :users, :through => :in_world_object_instances
  has_many :gifts, :as => :giftable, :dependent => :destroy
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  before_create :log_creation
  after_destroy :log_destruction

  mount_uploader :image, InWorldObjectUploader
  mount_uploader :app, AppUploader
  mount_uploader :icon, AppIconUploader
  
  validates :image,
              :presence => true, :if => lambda { self.kind == 'image' }

  validates :app,
              :presence => true, :if => lambda { self.kind == 'app' }

  
  def hash_for_api
    if self.kind == 'app'
      return {
        :name =>          self.name,
        :guid =>          self.guid,
        :kind =>          self.kind,
        :width =>         self.width,
        :height =>        self.height,
        
        :app =>           self.app.url,
        :icon =>          self.icon.url,
        :medium_icon =>   self.icon.medium.url,
        :small_icon =>    self.icon.small.url,
      }
    elsif self.kind == 'image'
      return {
        :name =>          self.name,
        :guid =>          self.guid,
        :kind =>          self.kind,
        :width =>         self.width,
        :height =>        self.height,
        
        :thumbnail =>     self.image.thumb.url,
        :medium =>        self.image.medium.url,
        :fullsize =>      self.image.url
      }
    else
      raise "unknown kind: #{self.kind}"
    end
  end
  
  def instances
    self.in_world_object_instances
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def log_creation
    Worlize.event_logger.info("action=in_world_object_created user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=in_world_object_destroyed user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
end
