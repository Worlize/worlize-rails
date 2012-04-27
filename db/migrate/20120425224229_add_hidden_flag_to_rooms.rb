class AddHiddenFlagToRooms < ActiveRecord::Migration
  def self.up
    add_column :rooms, :hidden, :boolean, :default => false
  end

  def self.down
    remove_column :rooms, :hidden
  end
end