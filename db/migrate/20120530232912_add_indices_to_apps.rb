class AddIndicesToApps < ActiveRecord::Migration
  def self.up
    add_index :apps, :guid
    add_index :apps, :creator_id
    add_index :app_instances, :guid
    add_index :app_instances, :room_id
  end

  def self.down
    remove_index :app_instances, :room_id
    remove_index :app_instances, :guid
    remove_index :apps, :creator_id
    remove_index :apps, :guid
  end
end