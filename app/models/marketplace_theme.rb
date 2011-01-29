class MarketplaceTheme < ActiveRecord::Base
  has_many :marketplace_categories, :dependent => :nullify
  has_many :marketplace_items, :dependent => :nullify
  
  validates :name,
              :presence => true
  
  validates :css,
              :presence => true,
              :length => { :maximum => 65535 }
end
