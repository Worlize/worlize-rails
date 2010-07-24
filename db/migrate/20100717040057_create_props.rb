class CreateProps < ActiveRecord::Migration
  def self.up
    create_table :props, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :creator
      t.string :name, :limit => 64
      t.integer :offset_x, :limit => 5
      t.integer :offset_y, :limit => 5
      t.integer :width, :limit => 5
      t.integer :height, :limit => 5
      t.boolean :active, :default => true
      t.integer :price, :limit => 11
      t.string :image
      t.timestamps
    end
    add_index :props, :guid
  end

  def self.down
    remove_index :props, :guid
    drop_table :props
  end
end
