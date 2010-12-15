class SetDefaultValueForInvites < ActiveRecord::Migration
  def self.up
    remove_column :users, :invites
    add_column :users, :invites, :integer, :default => 5
  end

  def self.down
    remove_column :users, :invites
    add_column :users, :invites, :integer
  end
end
