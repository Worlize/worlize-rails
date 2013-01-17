class AddModeratorsOnlyToRooms < ActiveRecord::Migration
  def up
    add_column :rooms, :moderators_only, :boolean, :default => false
    execute 'UPDATE `rooms` SET `moderators_only` = \'0\''
  end
  def down
    remove_column :rooms, :moderators_only
  end
end