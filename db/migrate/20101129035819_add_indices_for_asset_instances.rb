class AddIndicesForAssetInstances < ActiveRecord::Migration
  def self.up
    add_index :background_instances, :background_id
    add_index :avatar_instances, :avatar_id
    add_index :in_world_object_instances, :in_world_object_id
    add_index :prop_instances, :prop_id
  end

  def self.down
    remove_index :prop_instances, :prop_id
    remove_index :in_world_object_instances, :in_world_object_id
    remove_index :avatar_instances, :avatar_id
    remove_index :background_instances, :background_id
  end
end
