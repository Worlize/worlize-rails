class FixAuthlogiColumns < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.remove :failed_login_count
      t.integer :failed_login_count
      
      t.remove :login_count
      t.integer :login_count
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :failed_login_count
      t.string :failed_login_count
      
      t.remove :login_count
      t.string :login_count
    end
  end
end
