class MakeCreatorIdNotRequired < ActiveRecord::Migration
  def self.up
    change_column :marketplace_items, :marketplace_creator_id, :integer, :null => true
    change_column :marketplace_items, :item_id, :integer, :null => true
    change_column :marketplace_items, :item_type, :string, :null => true
  end

  def self.down
    change_column :marketplace_items, :item_type, :string, :null => false
    change_column :marketplace_items, :item_id, :integer, :null => false
    change_column :marketplace_items, :marketplace_creator_id, :integer, :null => false
  end
end
