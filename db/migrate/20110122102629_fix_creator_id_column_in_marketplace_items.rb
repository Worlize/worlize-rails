class FixCreatorIdColumnInMarketplaceItems < ActiveRecord::Migration
  def self.up
    rename_column :marketplace_items, :creator_id, :marketplace_creator_id
  end

  def self.down
    rename_column :marketplace_items, :marketplace_creator_id, :creator_id
  end
end
