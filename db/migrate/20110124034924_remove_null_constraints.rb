class RemoveNullConstraints < ActiveRecord::Migration
  def self.up
    change_column :marketplace_items, :name, :string, :null => true
    change_column :marketplace_items, :price, :integer, :null => true
  end

  def self.down
    change_column :marketplace_items, :price, :integer, :null => false
    change_column :marketplace_items, :name, :string, :null => false
  end
end
