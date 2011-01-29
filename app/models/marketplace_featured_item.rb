class MarketplaceFeaturedItem < ActiveRecord::Base
  acts_as_list :scope => :marketplace_category_id
  
  mount_uploader :carousel_image, MarketplaceCarouselImageUploader
  mount_uploader :carousel_thumbnail_image, MarketplaceCarouselThumbnailUploader
  
  belongs_to :creator, :class_name => 'User'
  belongs_to :marketplace_item
  belongs_to :marketplace_category
  
  validates :marketplace_item,
              :presence => true
              
  validates :marketplace_category,
              :presence => { :if => :active? }
  
  validates :marketplace_category_id,
              :uniqueness => { :scope => :marketplace_item_id, 
                               :message => 'already has this item featured.  Choose a different category.' }

  validates :carousel_image,
              :presence => { :if => :include_in_carousel? }

  validates :carousel_thumbnail_image,
              :presence => { :if => :include_in_carousel? }
              
  validate :item_must_be_on_sale
  
  
  private
  
  def item_must_be_on_sale
    if self.active? && !self.marketplace_item.on_sale?
      errors.add(:base, "The referenced marketplace item must be marked 'on sale' before you can feature it.")
    end
  end
end
