class AddTypeToMarketplaceFeaturedItems < ActiveRecord::Migration
  def self.up
    remove_index :marketplace_featured_items, :marketplace_category_id
    add_column :marketplace_featured_items, :item_type, :string
    add_index :marketplace_featured_items, [:marketplace_category_id, :item_type], :name => "index_on_category_and_type"
    
    say_with_time "Updated existing data" do
      MarketplaceFeaturedItem.all.each do |item|
        item.item_type = item.marketplace_item.item_type
        item.save
      end
    end
  end

  def self.down
    remove_index :marketplace_featured_items, :name => "index_on_category_and_type"
    remove_column :marketplace_featured_items, :item_type
    add_index :marketplace_featured_items, :marketplace_category_id
  end
end
