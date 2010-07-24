class AddPricingInformationToModels < ActiveRecord::Migration
  def self.up
    add_column :props, :currency_type, :integer, :size => 1
    add_column :avatars, :currency_type, :integer, :size => 1
    add_column :in_world_objects, :currency_type, :integer, :size => 1
    add_column :backgrounds, :currency_type, :integer, :size => 1
  end

  def self.down
    remove_column :backgrounds, :currency_type
    remove_column :in_world_objects, :currency_type
    remove_column :avatars, :currency_type
    remove_column :props, :currency_type
  end
end
