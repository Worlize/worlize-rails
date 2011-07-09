class CreatePaypalTransactions < ActiveRecord::Migration
  def self.up
    create_table :paypal_transactions do |t|
      # IPN Transaction Types
      t.string :txn_type, :limit => 48
      
      # Transaction and Notification-Related Variables
      t.string :custom_value, :limit => 255
      t.string :txn_id, :limit => 19
      t.string :receipt_id, :limit => 32
      
      # Buyer Information Variables      
      t.string :address_country, :limit => 64
      t.string :address_city, :limit => 40
      t.string :address_country_code, :limit => 2
      t.string :address_name, :limit => 128
      t.string :address_state, :limit => 40
      t.string :address_status, :limit => 12
      t.string :address_street, :limit => 200
      t.string :address_zip, :limit => 20
      t.string :contact_phone, :limit => 20
      t.string :first_name, :limit => 64
      t.string :last_name, :limit => 64
      t.string :payer_business_name, :limit => 127
      t.string :payer_email, :limit => 0127
      t.string :payer_id, :limit => 13
      
      # Payment Information Variables
      t.decimal :auth_amount, :precision => 10, :scale => 2
      t.datetime :auth_exp # format HH:MM:SS DD Mmm YY, YYYY PST
      t.string :auth_id, :limit => 19
      t.string :auth_status
      t.decimal :exchange_rate, :precision => 12, :scale => 6
      
      t.string :invoice, :limit => 127
      t.string :item_number, :limit => 127
      
      t.string :mc_currency, :limit => 3
      t.decimal :mc_fee, :precision => 10, :scale => 2
      t.decimal :mc_gross, :precision => 10, :scale => 2
      t.decimal :mc_handling, :precision => 10, :scale => 2
      t.decimal :mc_shipping, :precision => 10, :scale => 2

      # t.string :memo, :limit => 255
      # t.integer :num_cart_items, :limit => 4
      # 
      # t.string :option_name1, :limit => 64
      # t.string :option_selection1, :limit => 200
      # t.string :option_name2, :limit => 64
      # t.string :option_selection2, :limit => 200
      
      ### payer_status field
      t.boolean :payer_paypal_account_verified, :default => false
      
      t.datetime :payment_date

      t.string :payment_status, :limit => 32
      t.string :payment_type, :limit => 10
      t.string :pending_reason, :limit => 32
      t.string :protection_eligibility, :limit => 32
      
      t.integer :quantity, :limit => 4

      t.string :reason_code, :limit => 32

      t.decimal :remaining_settle, :precision => 10, :scale => 2
      t.decimal :settle_amount, :precision => 10, :scale => 2
      t.string :settle_currency, :limit => 3
      
      t.decimal :shipping, :precision => 10, :scale => 2
      t.string :shipping_method, :limit => 32
      
      t.decimal :tax, :precision => 10, :scale => 2
      t.string :transaction_entity
      
      t.datetime :case_creation_date
      t.string :case_id, :limit => 16
      t.string :case_type, :limit => 16
      
      
      
      t.timestamps
    end
  end

  def self.down
    drop_table :paypal_transactions
  end
end
