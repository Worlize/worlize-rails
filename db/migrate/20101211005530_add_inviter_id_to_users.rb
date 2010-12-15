class AddInviterIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :inviter_ide, :integer
  end

  def self.down
    remove_column :users, :inviter_ide
  end
end
