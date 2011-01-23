class MarketplaceItem < ActiveRecord::Base
  belongs_to :creator, :class_name => 'MarketplaceCreator', :foreign_key => 'marketplace_creator_id'
  belongs_to :category, :class_name => 'MarketplaceCategory', :foreign_key => 'marketplace_category_id'
  belongs_to :theme, :class_name => 'MarketplaceTheme', :foreign_key => 'marketplace_theme_id'
  belongs_to :item, :polymorphic => true
  has_many :featured_items, :class_name => 'MarketplaceFeaturedItem'
  has_many :purchase_records, :class_name => 'MarketplacePurchaseRecord'
  
  acts_as_taggable_on :tags
  
  validates :name, :presence => true
  validates :description, :length => { :minimum => 0, :maximum => 2500 }
  
end
