class InWorldObject < ActiveRecord::Base
  has_many :in_world_object_instances, :dependent => :destroy
  has_many :users, :through => :in_world_object_instances
  has_many :gifts, :as => :giftable
  has_one :marketplace_item, :as => :item
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid
  
  mount_uploader :image, InWorldObjectUploader
  
  validates :image,
              :presence => true
  
  def hash_for_api
    {
      :name =>          self.name,
      :guid =>          self.guid,
      :thumbnail =>     self.image.thumb.url,
      :medium =>        self.image.medium.url,
      :fullsize =>      self.image.url
    }
  end
  
  def instances
    self.in_world_object_instances
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
