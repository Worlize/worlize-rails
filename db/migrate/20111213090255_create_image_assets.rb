class CreateImageAssets < ActiveRecord::Migration
  def self.up
    create_table :image_assets do |t|
      t.string :name
      t.string :image
      t.integer :imageable_id
      t.string  :imageable_type
      t.timestamps
    end
  end

  def self.down
    drop_table :image_assets
  end
end
