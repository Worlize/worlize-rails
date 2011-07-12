class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.references :user_id
      t.references :paypal_transaction
      t.decimal    :amount, :precision => 10, :scale => 2
      t.string     :currency, :limit => 3, :default => 'USD'
      t.datetime   :created_at
    end
  end

  def self.down
    drop_table :payments
  end
end
