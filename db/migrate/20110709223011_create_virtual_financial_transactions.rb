class CreateVirtualFinancialTransactions < ActiveRecord::Migration
  def self.up
    create_table :virtual_financial_transactions do |t|
      t.references :user
      t.references :marketplace_item
      t.references :payment
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
      coins = user.coins
      bucks = user.bucks
      
      if coins > 0 || bucks > 0
        transaction = VirtualFinancialTransaction.new (
          :user => user,
          :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
          :comment => "Initial Balance"
        )
        if coins > 0
          transaction.coins_amount = coins
        end
        if bucks > 0
          transaction.bucks_amount = bucks
        end
        success = transaction.save
        if !success
          say "Unable to save initial balance transaction for user #{user.id} '#{user.username}'"
        end
      end
    end
  end

  def self.down
    remove_index :virtual_financial_transactions, :column_name
    drop_table :virtual_financial_transactions
  end
end
