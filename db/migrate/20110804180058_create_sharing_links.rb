class CreateSharingLinks < ActiveRecord::Migration
  def self.up
    create_table :sharing_links do |t|
      t.string :code
      t.references :user
      t.references :room
      t.datetime :expires_at
      t.integer :visits, :default => 0
      t.timestamps
    end
    
    add_index :sharing_links, :code
    add_index :sharing_links, :room_id
    add_index :sharing_links, :user_id
  end

  def self.down
    drop_table :sharing_links
  end
end