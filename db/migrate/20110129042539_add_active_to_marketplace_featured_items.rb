class AddActiveToMarketplaceFeaturedItems < ActiveRecord::Migration
  def self.up
    add_column :marketplace_featured_items, :active, :boolean, :default => false
  end

  def self.down
    remove_column :marketplace_featured_items, :active
  end
end
