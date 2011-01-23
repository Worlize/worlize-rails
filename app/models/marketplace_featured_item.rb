class MarketplaceFeaturedItem < ActiveRecord::Base
  acts_as_list :scope => :marketplace_category_id
  
  mount_uploader :carousel_image, MarketplaceCarouselImageUploader
  mount_uploader :carousel_thumbnail, MarketplaceCarouselThumbnailUploader
  
  belongs_to :item, :class_name => 'MarketplaceItem', :foreign_key => 'marketplace_item_id'
  belongs_to :category, :class_name => 'MarketplaceCategory', :foreign_key => 'marketplace_category_id'
end
