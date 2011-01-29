class AddCreatedByToMarketplaceItemsAndFeaturedItems < ActiveRecord::Migration
  def self.up
    add_column :marketplace_items, :creator_id, :integer
    add_column :marketplace_featured_items, :creator_id, :integer
  end

  def self.down
    remove_column :marketplace_featured_items, :creator_id
    remove_column :marketplace_items, :creator_id
  end
end
