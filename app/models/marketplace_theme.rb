class MarketplaceTheme < ActiveRecord::Base
  has_many :marketplace_categories
  has_many :marketplace_items
  
  validates :name
              :presence => true
  
  validates :css
              :presence => true,
              :length => { :maximum => 65535 }
end
