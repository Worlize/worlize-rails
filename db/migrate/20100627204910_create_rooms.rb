class CreateRooms < ActiveRecord::Migration
  def self.up
    create_table :rooms do |t|
      t.string :guid
      t.string :name
      t.integer :world_id
      t.timestamps
    end
    add_index :rooms, :guid
    add_index :rooms, :world_id
  end

  def self.down
    drop_table :rooms
  end
end
