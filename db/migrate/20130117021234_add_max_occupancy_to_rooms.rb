class AddMaxOccupancyToRooms < ActiveRecord::Migration
  def up
    add_column :rooms, :max_occupancy, :integer, :default => 20
    execute 'UPDATE `rooms` SET `max_occupancy` = 20'
  end
  def down
    remove_column :rooms, :max_occupancy
  end
end