class CreateMarketplaceItemGiveaways < ActiveRecord::Migration
  def self.up
    create_table :marketplace_item_giveaways do |t|
      t.references :promo_program
      t.references :marketplace_item
      t.string :name
      t.text :description
      t.date :date
            
      t.timestamps
    end
    add_index :marketplace_item_giveaways, :date
    add_index :marketplace_item_giveaways, :promo_program_id
    add_index :marketplace_item_giveaways, :marketplace_item_id
  end

  def self.down
    remove_index :marketplace_item_giveaways, :marketplace_item_id
    remove_index :marketplace_item_giveaways, :promo_program_id
    remove_index :marketplace_item_giveaways, :date
    drop_table :marketplace_item_giveaways
  end
end