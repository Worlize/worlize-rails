class AddFirstAndLastNameToBetaInvitations < ActiveRecord::Migration
  def self.up
    add_column :beta_invitations, :first_name, :string
    add_column :beta_invitations, :last_name, :string
  end

  def self.down
    remove_column :beta_invitations, :last_name
    remove_column :beta_invitations, :first_name
  end
end
