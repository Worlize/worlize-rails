class AddMarketplaceLicenseIdToMarketplaceItems < ActiveRecord::Migration
  def self.up
    add_column :marketplace_items, :marketplace_license_id, :integer
  end

  def self.down
    remove_column :marketplace_items, :marketplace_license_id
  end
end
