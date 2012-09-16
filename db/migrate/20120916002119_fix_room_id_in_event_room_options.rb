class FixRoomIdInEventRoomOptions < ActiveRecord::Migration
  def up
    remove_column :event_room_options, :room_id_id
    add_column :event_room_options, :room_id, :integer
  end

  def down
    remove_column :event_room_options, :room_id
    add_column :event_room_options, :room_id_id, :integer
  end
end