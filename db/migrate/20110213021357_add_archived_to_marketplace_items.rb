class AddArchivedToMarketplaceItems < ActiveRecord::Migration
  def self.up
    add_column :marketplace_items, :archived, :boolean, :default => false
    MarketplaceItem.update_all(['archived = ?', false])
  end

  def self.down
    remove_column :marketplace_items, :archived
  end
end
