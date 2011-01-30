class CreateMarketplaceLicenses < ActiveRecord::Migration
  def self.up
    create_table :marketplace_licenses do |t|
      t.string :name
      t.text :description
      t.string :details_link
      t.timestamps
    end
  end

  def self.down
    drop_table :marketplace_licenses
  end
end
