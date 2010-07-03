class AddAuthToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string      :email,               :null => false
      t.string      :crypted_password,    :null => false
      t.string      :password_salt,       :null => false
      t.string      :persistence_token,   :null => false
      t.string      :single_access_token, :null => false
      t.string      :perishable_token,    :null => false
      t.string      :login_count,         :null => false, :default => 0
      t.string      :failed_login_count,  :null => false, :default => 0
      t.datetime    :last_login_at
      t.string      :last_login_ip
    end
    add_index :users, :email
  end

  def self.down
    remove_index :users, :email
    change_table :users do |t|
      t.remove    :email,
                  :crypted_password,
                  :password_salt,
                  :persistence_token,
                  :single_access_token,
                  :perishable_token,
                  :login_count,
                  :failed_login_count,
                  :last_login_at,
                  :last_login_ip
    end
  end
end
