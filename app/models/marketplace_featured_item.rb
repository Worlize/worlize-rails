class MarketplaceFeaturedItem < ActiveRecord::Base
  acts_as_list
  
  mount_uploader :carousel_image, MarketplaceCarouselImageUploader
  mount_uploader :carousel_thumbnail_image, MarketplaceCarouselThumbnailUploader
  
  belongs_to :creator, :class_name => 'User'
  belongs_to :marketplace_category
  belongs_to :featured_item, :polymorphic => true
  has_one :marketplace_carousel_item, :dependent => :destroy
  
  before_save :sync_item_type
  after_save :sync_marketplace_carousel_item
  
  scope :avatars, lambda {
    where(:featured_item_type => 'MarketplaceItem', :item_type => 'Avatar')
  }
  
  scope :backgrounds, lambda {
    joins("JOIN #{connection.quote_table_name("marketplace_items")} ON #{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("id")} = #{connection.quote_table_name("marketplace_featured_items")}.#{connection.quote_column_name("featured_item_id")}").
    where(:featured_item_type => 'MarketplaceItem').
    where("#{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("item_type")} = #{connection.quote("Background")}")
  }
  
  scope :in_world_objects, lambda {
    joins("JOIN #{connection.quote_table_name("marketplace_items")} ON #{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("id")} = #{connection.quote_table_name("marketplace_featured_items")}.#{connection.quote_column_name("featured_item_id")}").
    where(:featured_item_type => 'MarketplaceItem').
    where("#{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("item_type")} = #{connection.quote("InWorldObject")}")
  }
  
  scope :props, lambda {
    joins("JOIN #{connection.quote_table_name("marketplace_items")} ON #{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("id")} = #{connection.quote_table_name("marketplace_featured_items")}.#{connection.quote_column_name("featured_item_id")}").
    where(:featured_item_type => 'MarketplaceItem').
    where("#{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("item_type")} = #{connection.quote("Prop")}")
  }
  
  scope :apps, lambda {
    joins("JOIN #{connection.quote_table_name("marketplace_items")} ON #{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("id")} = #{connection.quote_table_name("marketplace_featured_items")}.#{connection.quote_column_name("featured_item_id")}").
    where(:featured_item_type => 'MarketplaceItem').
    where("#{connection.quote_table_name("marketplace_items")}.#{connection.quote_column_name("item_type")} = #{connection.quote("App")}")
  }
  
  scope :categories, lambda {
    where(:featured_item_type => 'MarketplaceCategory')
  }
  
  scope :included_in_carousel, lambda {
    where(:include_in_carousel => true)
  }
  
  scope :not_included_in_carousel, lambda {
    where(:include_in_carousel => false)
  }
  
  scope :active, lambda {
    where(:active => true)
  }
  
  scope :in_category, lambda { |category_id|
    if category_id.instance_of? MarketplaceCategory
      category_id = category_id.id
    end
    where(:marketplace_category_id => category_id)
  }
  
  validates :featured_item,
              :presence => true
              
  validates :marketplace_category,
              :presence => { :if => :active? }
  
  validates :marketplace_category_id,
              :uniqueness => { :scope => :featured_item_id, 
                               :message => 'already has this item featured.  Choose a different category.' }

  validates :carousel_image,
              :presence => { :if => :include_in_carousel? }

  validates :carousel_thumbnail_image,
              :presence => { :if => :include_in_carousel? }
              
  validate :item_must_be_on_sale
  
  def name
    if !self.featured_item.nil? && self.featured_item.respond_to?('name')
      self.featured_item.name
    else
      ''
    end
  end
  
  def slug
    if self.name.nil?
      self.id.to_s
    else
      "#{self.id}-#{self.name}"
    end
  end
  
  private
  
  def item_must_be_on_sale
    if self.active? && (self.featured_item.respond_to?('on_sale?') && !self.featured_item.on_sale?)
      errors.add(:base, "The referenced marketplace item must be marked 'on sale' before you can feature it.")
    end
  end
  
  def scope_condition
    "#{connection.quote_column_name("marketplace_category_id")} = #{marketplace_category_id} AND " +
    "#{connection.quote_column_name("item_type")} = #{connection.quote(item_type)}"
  end
  
  def sync_item_type
    if self.featured_item_type == 'MarketplaceItem' && self.featured_item
      self.item_type = self.featured_item.item_type
    else
      self.item_type = self.featured_item_type
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
