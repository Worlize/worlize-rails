class CreateBackgrounds < ActiveRecord::Migration
  def self.up
    create_table :backgrounds, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8'  do |t|
      t.references :creator
      t.string :guid, :limit => 36
      t.string :name, :limit => 64
      t.integer :width, :limit => 5
      t.integer :height, :limit => 5
      t.boolean :active, :default => true
      t.integer :price, :limit => 11
      t.string :image
      t.timestamps
    end
  end

  def self.down
    drop_table :backgrounds
  end
end
