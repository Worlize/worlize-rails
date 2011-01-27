class CreateMarketplaceTagContexts < ActiveRecord::Migration
  def self.up
    create_table :marketplace_tag_contexts do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :marketplace_tag_contexts
  end
end
