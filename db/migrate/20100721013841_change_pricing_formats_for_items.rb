class ChangePricingFormatsForItems < ActiveRecord::Migration
  def self.up
    rename_column :backgrounds, :price, :sale_coins
    rename_column :props, :price, :sale_coins
    rename_column :in_world_objects, :price, :sale_coins
    rename_column :avatars, :price, :sale_coins
    
    remove_column :backgrounds, :currency_type
    remove_column :avatars, :currency_type
    remove_column :props, :currency_type
    remove_column :in_world_objects, :currency_type
    
    add_column :backgrounds, :sale_bucks, :integer
    add_column :avatars, :sale_bucks, :integer
    add_column :props, :sale_bucks, :integer
    add_column :in_world_objects, :sale_bucks, :integer
    
    add_column :backgrounds, :return_coins, :integer
    add_column :avatars, :return_coins, :integer
    add_column :props, :return_coins, :integer
    add_column :in_world_objects, :return_coins, :integer
  end

  def self.down
    remove_column :in_world_objects, :return_coins
    remove_column :props, :return_coins
    remove_column :avatars, :return_coins
    remove_column :backgrounds, :return_coins
    remove_column :in_world_objects, :sale_bucks
    remove_column :props, :sale_bucks
    remove_column :avatars, :sale_bucks
    remove_column :backgrounds, :sale_bucks
    
    add_column :in_world_objects, :currency_type, :integer
    add_column :props, :currency_type, :integer
    add_column :avatars, :currency_type, :integer
    add_column :backgrounds, :currency_type, :integer

    rename_column :avatars, :sale_coins, :price
    rename_column :in_world_objects, :sale_coins, :price
    rename_column :props, :sale_coins, :price
    rename_column :backgrounds, :sale_coins, :price
  end
end
