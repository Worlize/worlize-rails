class MarketplaceCreator < ActiveRecord::Base
  belongs_to :user
  has_many :marketplace_items
  
  validates :display_name,
              :presence => true
  
end
