class CreateCurrenciesTable < ActiveRecord::Migration
  def self.up
    create_table :currencies, :force => true do |t|
      t.string :name
    end
    
    execute <<-SQL
      INSERT INTO currencies SET id = '1', name = 'Bucks'
    SQL
    execute <<-SQL
      INSERT INTO currencies SET id = '2', name = 'Coins'
    SQL
  end

  def self.down
    drop_table :currencies
  end
end
