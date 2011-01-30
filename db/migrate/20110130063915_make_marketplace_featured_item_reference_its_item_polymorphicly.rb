class MakeMarketplaceFeaturedItemReferenceItsItemPolymorphicly < ActiveRecord::Migration
  def self.up
    MarketplaceFeaturedItem.delete_all
    MarketplaceCarouselItem.delete_all
    remove_column :marketplace_featured_items, :marketplace_item_id
    add_column :marketplace_featured_items, :featured_item_id, :integer
    add_column :marketplace_featured_items, :featured_item_type, :string, :limit => 64
    add_index :marketplace_featured_items, [:featured_item_id, :featured_item_type], :name => "index_on_item_id_and_type"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
