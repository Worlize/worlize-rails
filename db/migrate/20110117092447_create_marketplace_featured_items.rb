class CreateMarketplaceFeaturedItems < ActiveRecord::Migration
  def self.up
    create_table :marketplace_featured_items do |t|
      t.references :marketplace_item
      t.references :marketplace_category
      t.boolean :include_in_carousel, :default => false
      t.integer :position, :default => 1
      t.timestamps
    end
    
    add_index :marketplace_featured_items, :marketplace_category_id
    add_index :marketplace_featured_items, :marketplace_item_id
  end

  def self.down
    drop_table :marketplace_featured_items
  end
end
