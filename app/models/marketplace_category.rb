class MarketplaceCategory < ActiveRecord::Base
  acts_as_tree :order => 'position, name'
  acts_as_list :scope => :parent_id
  
  has_many :featured_items, :class_name => 'MarketplaceFeaturedItem'
  has_many :items, :class_name => 'MarketplaceItem'
  belongs_to :theme, :class_name => 'MarketplaceTheme', :foreign_key => 'marketplace_theme_id'
  
  validates :name, :presence => true
end
