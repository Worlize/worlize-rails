class MarketplaceFeaturedItem < ActiveRecord::Base
  acts_as_list :scope => :marketplace_category_id
  
  mount_uploader :carousel_image, MarketplaceCarouselImageUploader
  mount_uploader :carousel_thumbnail, MarketplaceCarouselThumbnailUploader
  
  belongs_to :marketplace_item
  belongs_to :marketplace_category
  
  validates :marketplace_item,
              :presence => true

  validates :carousel_image,
              :presence => { :if => :include_in_carousel? }

  validates :carousel_thumbnail,
              :presence => { :if => :include_in_carousel? }
end
