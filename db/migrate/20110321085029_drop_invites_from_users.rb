class DropInvitesFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :invites
  end

  def self.down
    add_column :users, :invites, :integer,                             :default => 5
  end
end
