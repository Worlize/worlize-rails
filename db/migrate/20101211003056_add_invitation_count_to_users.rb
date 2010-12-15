class AddInvitationCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :invites, :integer
  end

  def self.down
    remove_column :users, :invites
  end
end
