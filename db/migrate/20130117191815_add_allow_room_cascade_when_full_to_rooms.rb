class AddAllowRoomCascadeWhenFullToRooms < ActiveRecord::Migration
  def up
    add_column :rooms, :allow_cascade_when_full, :boolean, :default => true
    execute 'UPDATE `rooms` SET `allow_cascade_when_full` = \'1\''
  end
  
  def down
    remove_column :rooms, :allow_cascade_when_full
  end
end