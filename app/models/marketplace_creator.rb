class MarketplaceCreator < ActiveRecord::Base
  belongs_to :user
  has_many :items, :class_name => 'MarketplaceItem'
end
