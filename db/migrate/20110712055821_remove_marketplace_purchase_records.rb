class RemoveMarketplacePurchaseRecords < ActiveRecord::Migration
  def self.up
    MarketplacePurchaseRecord.all.each do |record|
      transaction = VirtualFinancialTransaction.new(
        :user_id => record.user_id,
        :marketplace_item_id => record.marketplace_item_id,
        :kind => VirtualFinancialTransaction::KIND_DEBIT_ITEM_PURCHASE
      )
      if record.currency_id == 1
        transaction.bucks_amount = record.purchase_price
      elsif record.currency_id == 2
        transaction.coins_amount = record.purchase_price
      end
      
      transaction.save!
    end
    
    drop_table :marketplace_purchase_records
  end

  def self.down
    create_table "marketplace_purchase_records", :force => true do |t|
      t.integer  "user_id"
      t.integer  "marketplace_item_id"
      t.integer  "currency_id"
      t.integer  "purchase_price"
      t.datetime "created_at"
    end
  end
end
