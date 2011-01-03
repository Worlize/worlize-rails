class AddBetaCodeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :beta_code_id, :integer
    add_column :beta_invitations, :beta_code_id, :integer
  end

  def self.down
    remove_column :beta_invitations, :beta_code_id
    remove_column :users, :beta_code_id
  end
end
