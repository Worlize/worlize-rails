class CreatePublicWorlds < ActiveRecord::Migration
  def self.up
    create_table :public_worlds do |t|
      t.integer :world_id
      t.timestamps
    end
    add_index :public_worlds, :world_id
  end

  def self.down
    remove_index :public_worlds, :world_id
    drop_table :public_worlds
  end
end
