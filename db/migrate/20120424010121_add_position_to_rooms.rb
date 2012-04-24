class AddPositionToRooms < ActiveRecord::Migration
  def self.up
    add_column :rooms, :position, :integer
    add_column :rooms, :drop_zone, :boolean, :default => false
  end

  def self.down
    remove_column :rooms, :drop_zone
    remove_column :rooms, :position
  end
end