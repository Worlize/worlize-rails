class AddForSaleToItems < ActiveRecord::Migration
  def self.up
    add_column :backgrounds, :on_sale, :boolean, :default => false
    add_column :avatars, :on_sale, :boolean, :default => false
    add_column :in_world_objects, :on_sale, :boolean, :default => false
    add_column :props, :on_sale, :boolean, :default => false
  end

  def self.down
    remove_column :props, :on_sale
    remove_column :in_world_objects, :on_sale
    remove_column :avatars, :on_sale
    remove_column :backgrounds, :on_sale
  end
end
