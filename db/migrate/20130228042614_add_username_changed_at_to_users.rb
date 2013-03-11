class AddUsernameChangedAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :username_changed_at, :datetime
  end
  
  def down
    remove_column :users, :username_changed_at
  end
end