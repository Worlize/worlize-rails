class AddLoginNameToUsers < ActiveRecord::Migration
  def up
    add_column :users, :login_name, :string
    add_index :users, :login_name, :limit => 36
    execute "UPDATE `users` SET `login_name` = `username`"
    execute "UPDATE `users` SET `state` = 'login_name_unconfirmed' WHERE `state` = 'user_ready'"
  end
  def down
    execute "UPDATE `users` SET `state` = 'user_ready' WHERE `state` = 'login_name_unconfirmed'"
    remove_column :users, :login_name
  end
end