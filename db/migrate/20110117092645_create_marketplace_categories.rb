class CreateMarketplaceCategories < ActiveRecord::Migration
  def self.up
    create_table :marketplace_categories do |t|
      t.references :parent
      t.references :marketplace_theme
      t.string :name
      t.integer :position, :default => 1
      t.timestamps
    end

    add_index :marketplace_categories, :parent_id
  end

  def self.down
    drop_table :marketplace_categories
  end
end
