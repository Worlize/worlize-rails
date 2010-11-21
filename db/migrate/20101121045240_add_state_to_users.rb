class AddStateToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :state, :string, :default => 'new_user'
    User.update_all(:state => 'new_user')
  end

  def self.down
    remove_column :users, :state
  end
end
