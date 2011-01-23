class CreateMarketplaceCreators < ActiveRecord::Migration
  def self.up
    create_table :marketplace_creators do |t|
      t.string :display_name, :limit => 48
      t.references :user
    end
    
    add_index :marketplace_creators, :display_name, :length => 36
    add_index :marketplace_creators, :user_id
  end

  def self.down
    remove_index :marketplace_creators, :display_name
    remove_index :marketplace_creators, :user_id
    drop_table :marketplace_creators
  end
end
