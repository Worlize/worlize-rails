class SetMarketplaceItemsOnSaleDefaultToFalse < ActiveRecord::Migration
  def self.up
    change_column_default :marketplace_items, :on_sale, false
  end

  def self.down
    change_column_default :marketplace_items, :on_sale, true
  end
end
