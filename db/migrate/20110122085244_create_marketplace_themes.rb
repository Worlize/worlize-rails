class CreateMarketplaceThemes < ActiveRecord::Migration
  def self.up
    create_table :marketplace_themes do |t|
      t.string :name
      t.text :css
      t.timestamps
    end
  end

  def self.down
    drop_table :marketplace_themes
  end
end
