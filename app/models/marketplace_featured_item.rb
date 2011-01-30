class MarketplaceFeaturedItem < ActiveRecord::Base
  acts_as_list
  
  mount_uploader :carousel_image, MarketplaceCarouselImageUploader
  mount_uploader :carousel_thumbnail_image, MarketplaceCarouselThumbnailUploader
  
  belongs_to :creator, :class_name => 'User'
  belongs_to :marketplace_item
  belongs_to :marketplace_category
  has_one :marketplace_carousel_item, :dependent => :destroy
  
  before_save :sync_item_type
  after_save :sync_marketplace_carousel_item
  
  scope :avatars, lambda {
    where(:item_type => 'Avatar')
  }
  
  scope :backgrounds, lambda {
    where(:item_type => 'Background')
  }
  
  scope :in_world_objects, lambda {
    where(:item_type => 'InWorldObject')
  }
  
  scope :categories, lambda {
    where(:item_type => 'MarketplaceCategory')
  }
  
  scope :included_in_carousel, lambda {
    where(:include_in_carousel => true)
  }
  
  scope :not_included_in_carousel, lambda {
    where(:include_in_carousel => false)
  }
  
  scope :in_category, lambda { |category_id|
    if category_id.instance_of? MarketplaceCategory
      category_id = category_id.id
    end
    where(:marketplace_category_id => category_id)
  }
  
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
  
  def scope_condition
    "#{connection.quote_column_name("marketplace_category_id")} = #{marketplace_category_id} AND " +
    "#{connection.quote_column_name("item_type")} = #{connection.quote(item_type)}"
  end
  
  def sync_item_type
    if self.marketplace_item
      self.item_type = self.marketplace_item.item_type
    end
  end
  
  def sync_marketplace_carousel_item
    if self.include_in_carousel?
      if self.marketplace_carousel_item
        self.marketplace_carousel_item.update_attributes(:marketplace_category => self.marketplace_category)
      else
        MarketplaceCarouselItem.create(
          :marketplace_featured_item => self,
          :marketplace_category => self.marketplace_category
        )
      end
    else
      if self.marketplace_carousel_item
        self.marketplace_carousel_item.destroy
      end
    end
  end
end
