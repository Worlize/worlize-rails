class CreateMarketplaceItemGiveawayReceipts < ActiveRecord::Migration
  def self.up
    create_table :marketplace_item_giveaway_receipts do |t|
      t.references :user
      t.references :marketplace_item_giveaway
      t.timestamps
    end
    add_index :marketplace_item_giveaway_receipts, :user_id
    add_index :marketplace_item_giveaway_receipts, :marketplace_item_giveaway_id, :name => "index_marketplace_item_giveaway_id"
  end

  def self.down
    remove_index :marketplace_item_giveaway_receipts, :name => "index_marketplace_item_giveaway_id"
    remove_index :marketplace_item_giveaway_receipts, :user_id
    drop_table :marketplace_item_giveaway_receipts
  end
end