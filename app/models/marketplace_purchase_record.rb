class MarketplacePurchaseRecord < ActiveRecord::Base
  belongs_to :user
  belongs_to :item, :class_name => 'MarketplaceItem', :foreign_key => 'marketplace_item_id'
end
