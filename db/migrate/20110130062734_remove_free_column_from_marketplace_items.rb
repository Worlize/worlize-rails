class RemoveFreeColumnFromMarketplaceItems < ActiveRecord::Migration
  def self.up
    remove_column :marketplace_items, :free
  end

  def self.down
    add_column :marketplace_items, :free, :boolean, :default => true
  end
end
