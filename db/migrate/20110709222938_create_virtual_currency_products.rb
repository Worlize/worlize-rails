class CreateVirtualCurrencyProducts < ActiveRecord::Migration
  def self.up
    create_table :virtual_currency_products do |t|
      t.string  :guid
      t.integer :position
      t.string  :name
      t.text    :description
      t.integer :coins_to_add
      t.integer :bucks_to_add
      t.string  :currency, :limit => 3
      t.decimal :price, :precision => 10, :scale => 2
      t.boolean :archived, :default => false
      t.timestamps
    end
    
    add_index :virtual_currency_products, :guid
  end

  def self.down
    drop_table :virtual_currency_products
  end
end
