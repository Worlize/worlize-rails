class AddPasswordChangedAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :password_changed_at, :datetime
    User.reset_column_information
    say_with_time("Setting :password_changed_at => user.created_at on existing Users with passwords") do
      User.find_each do |user|
        user.update_attribute(:password_changed_at, user.created_at) unless user.crypted_password.nil?
      end
    end
  end

  def self.down
    remove_column :users, :password_changed_at
  end
end