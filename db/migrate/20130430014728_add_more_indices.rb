class AddMoreIndices < ActiveRecord::Migration
  def up
    add_index :client_error_log_items, :created_at
    add_index :in_world_object_instances, :room_id
  end

  def down
    remove_index :in_world_object_instances, :room_id
    remove_index :client_error_log_items, :created_at
  end
end