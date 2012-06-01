class App < ActiveRecord::Base
  has_many :app_instances, :dependent => :destroy
  has_many :users, :through => :app_instances
  has_many :gifts, :as => :giftable, :dependent => :destroy
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  before_create :log_creation
  after_destroy :log_destruction
  
  mount_uploader :app, AppUploader
  mount_uploader :icon, AppIconUploader

  def hash_for_api
    return {
      :name =>          self.name,
      :description =>   self.description,
      :tagline =>       self.tagline,
      :help =>          self.help,
      :guid =>          self.guid,
      :width =>         self.width,
      :height =>        self.height,
      :app_url =>       self.app.url,
      :icon =>          self.icon.url,
      :medium_icon =>   self.icon.medium.url,
      :small_icon =>    self.icon.small.url
    }
  end
  
  def instances
    self.app_instances
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s if self.guid.nil?
  end
  
  def log_creation
    Worlize.event_logger.info("action=app_created user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=app_destroyed user=#{self.creator ? self.creator.guid : 'none'} user_username=\"#{self.creator ? self.creator.username : ''}\" guid=#{self.guid}")
  end
  
end
