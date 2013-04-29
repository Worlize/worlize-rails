class AddMissingIndices < ActiveRecord::Migration
  def up
    add_index :background_instances, :room_id
    add_index :authentications, :user_id
  end

  def down
    remove_index :authentications, :user_id
    remove_index :background_instances, :room_id
  end
end