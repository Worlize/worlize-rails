class EventTheme < ActiveRecord::Base
  acts_as_list :scope => :event_category_id
  
  attr_accessible :name, :thumbnail, :header_image, :header_background
  has_one :thumbnail, :as => :imageable
  belongs_to :event_category
  has_many :event_room_options
  
  mount_uploader :thumbnail, ImageUploader
  mount_uploader :header_image, ImageUploader
  mount_uploader :header_background, ImageUploader
  
  validates :name, :presence => true

  def header_image_thumbnail_dimensions
    [600,300]
  end
  
  def header_background_thumbnail_dimensions
    [600,300]
  end
  
end
