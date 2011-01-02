class AddInstanceOwnerIndexToAssets < ActiveRecord::Migration
  def self.up
    add_index :avatar_instances, :user_id
    add_index :background_instances, :user_id
    add_index :in_world_object_instances, :user_id
    add_index :prop_instances, :user_id
  end

  def self.down
    remove_index :prop_instances, :user_id
    remove_index :in_world_object_instances, :user_id
    remove_index :background_instances, :user_id
    remove_index :avatar_instances, :user_id
  end
end
