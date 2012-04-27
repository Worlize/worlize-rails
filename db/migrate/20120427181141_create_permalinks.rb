class CreatePermalinks < ActiveRecord::Migration
  def self.up
    create_table :permalinks do |t|
      t.string :link, :limit => 40
      t.integer :linkable_id
      t.string :linkable_type
      t.timestamps
    end
    
    add_index :permalinks, :link, :unique => true
    add_index :permalinks, [:linkable_type, :linkable_id]
  end

  def self.down
    drop_table :permalinks
  end
end