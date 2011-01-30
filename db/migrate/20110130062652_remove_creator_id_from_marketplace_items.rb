class RemoveCreatorIdFromMarketplaceItems < ActiveRecord::Migration
  def self.up
    remove_column :marketplace_items, :creator_id
  end

  def self.down
    add_column :marketplace_items, :creator_id, :integer
  end
end
