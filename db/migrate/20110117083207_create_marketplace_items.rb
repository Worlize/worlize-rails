class CreateMarketplaceItems < ActiveRecord::Migration
  def self.up
    create_table :marketplace_items do |t|
      t.references :marketplace_category
      t.references :item, {:polymorphic => { :limit => 32, :null => false }, :null => false}
      t.references :creator, :null => false
      t.references :marketplace_theme
      t.string :copyright # For misc copyright-notices
      t.column :name, :string, :null => false
      t.column :description, :text
      t.boolean :on_sale, :default => true
      t.boolean :free, :default => false
      t.integer :price, :null => false
      t.integer :currency_id, :default => 1
      t.integer :purchase_count
      t.timestamps
    end
    
    add_index :marketplace_items, :marketplace_category_id
    add_index :marketplace_items, [:item_type, :item_id]
    add_index :marketplace_items, :created_at
    
    
    remove_column :avatars, :sale_coins
    remove_column :avatars, :sale_bucks
    remove_column :avatars, :on_sale
    remove_column :avatars, :return_coins
    
    remove_column :backgrounds, :sale_coins
    remove_column :backgrounds, :sale_bucks
    remove_column :backgrounds, :on_sale
    remove_column :backgrounds, :return_coins
    
    remove_column :in_world_objects, :sale_coins
    remove_column :in_world_objects, :sale_bucks
    remove_column :in_world_objects, :on_sale
    remove_column :in_world_objects, :return_coins
    
    remove_column :props, :sale_coins
    remove_column :props, :sale_bucks
    remove_column :props, :on_sale
    remove_column :props, :return_coins
  end

  def self.down
    add_column :props, :return_coins, :integer
    add_column :props, :on_sale, :boolean,                    :default => false
    add_column :props, :sale_bucks, :integer
    add_column :props, :sale_coins, :integer

    add_column :in_world_objects, :return_coins, :integer
    add_column :in_world_objects, :on_sale, :boolean,                    :default => false
    add_column :in_world_objects, :sale_bucks, :integer
    add_column :in_world_objects, :sale_coins, :integer

    add_column :backgrounds, :return_coins, :integer
    add_column :backgrounds, :on_sale, :boolean,                    :default => false
    add_column :backgrounds, :sale_bucks, :integer
    add_column :backgrounds, :sale_coins, :integer

    add_column :avatars, :return_coins, :integer
    add_column :avatars, :on_sale, :boolean,                    :default => false
    add_column :avatars, :sale_bucks, :integer
    add_column :avatars, :sale_coins, :integer

    drop_table :marketplace_items
  end
end
