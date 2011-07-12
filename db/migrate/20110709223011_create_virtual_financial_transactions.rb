class CreateVirtualFinancialTransactions < ActiveRecord::Migration
  def self.up
    create_table :virtual_financial_transactions do |t|
      t.references :user
      t.references :marketplace_item
      t.integer    :kind
      t.integer    :coins_amount
      t.integer    :bucks_amount
      t.string     :comment
      t.datetime   :created_at
    end
    
    add_index :virtual_financial_transactions, :user_id
    add_index :virtual_financial_transactions, :marketplace_item_id
    
    User.all.each do |user|
      redis = Worlize::RedisConnectionPool.get_client(:currency)
      coins = redis.get("coins:#{user.guid}").to_i
      bucks = redis.get("bucks:#{user.guid}").to_i
      
      if coins > 0
        VirtualFinancialTransaction.create! (
          :user => user,
          :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
          :coins_amount => coins,
          :comment => "Initial Balance"
        )
      end
      
      if bucks > 0
        VirtualFinancialTransaction.create! (
          :user => user,
          :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
          :bucks_amount => bucks,
          :comment => "Initial Balance"
        )
      end
    end
  end

  def self.down
    remove_index :table_name, :column_name
    drop_table :virtual_financial_transactions
  end
end
