class MarketplaceTheme < ActiveRecord::Base
  has_many :marketplace_categories
  has_many :marketplace_items
end
