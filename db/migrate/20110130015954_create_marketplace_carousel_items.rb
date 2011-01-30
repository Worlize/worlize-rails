class CreateMarketplaceCarouselItems < ActiveRecord::Migration
  def self.up
    create_table :marketplace_carousel_items do |t|
      t.references :marketplace_featured_item
      t.references :marketplace_category
      t.integer :position
    end
    say_with_time "Updating existing data" do
      MarketplaceFeaturedItem.included_in_carousel.each do |item|
        item.save
      end
    end
  end

  def self.down
    drop_table :marketplace_carousel_items
  end
end
