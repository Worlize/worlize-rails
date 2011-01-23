class OptimizeUserNameFieldAndIndex < ActiveRecord::Migration
  def self.up
    change_column :users, :username, :string, :limit => 36
    remove_index :users, :username
    add_index :users, :username, :length => 36
  end

  def self.down
    remove_index :users, :username
    add_index :users, :username
    change_column :users, :username, :string, :limit => 255
  end
end
