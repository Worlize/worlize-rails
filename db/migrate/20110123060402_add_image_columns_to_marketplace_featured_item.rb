class AddImageColumnsToMarketplaceFeaturedItem < ActiveRecord::Migration
  def self.up
    add_column :marketplace_featured_items, :carousel_image, :string
    add_column :marketplace_featured_items, :carousel_thumbnail_image, :string
  end

  def self.down
    remove_column :marketplace_featured_items, :carousel_thumbnail_image
    remove_column :marketplace_featured_items, :carousel_image
  end
end
