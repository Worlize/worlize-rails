class CreateMarketplacePurchaseRecords < ActiveRecord::Migration
  def self.up
    create_table :marketplace_purchase_records do |t|
      t.references :user
      t.references :marketplace_item
      t.integer :currency_id
      t.integer :purchase_price
      t.datetime :created_at
    end
    
    add_index :marketplace_purchase_records, :marketplace_item_id
    add_index :marketplace_purchase_records, :user_id
    add_index :marketplace_purchase_records, :created_at
  end

  def self.down
    drop_table :marketplace_purchase_records
  end
end
