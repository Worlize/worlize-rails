class AddNoDirectEntryToRooms < ActiveRecord::Migration
  def change
    add_column :rooms, :no_direct_entry, :boolean, :default => false
  end
end