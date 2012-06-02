class AddIndexOnAppInstancesUserId < ActiveRecord::Migration
  def self.up
    add_index :app_instances, :user_id
  end

  def self.down
    remove_index :app_instances, :user_id
  end
end