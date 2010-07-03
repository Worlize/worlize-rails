class CreateWorlds < ActiveRecord::Migration
  def self.up
    create_table :worlds do |t|
      t.string :guid, :limit => 36
      t.string :name
      t.integer :user_id
      t.timestamps
    end
    add_index :worlds, :guid
    add_index :worlds, :user_id
  end

  def self.down
    drop_table :worlds
  end
end
