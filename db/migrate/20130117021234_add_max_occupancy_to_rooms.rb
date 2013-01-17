class AddMaxOccupancyToRooms < ActiveRecord::Migration
  def change
    add_column :rooms, :max_occupancy, :integer, :default => 20
  end
end