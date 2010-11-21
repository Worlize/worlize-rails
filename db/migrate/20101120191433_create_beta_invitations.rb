class CreateBetaInvitations < ActiveRecord::Migration
  def self.up
    create_table :beta_invitations do |t|
      t.column :inviter_id, :integer
      t.column :name, :string
      t.column :email, :string
      t.column :invite_code, :string
      t.timestamps
    end
    add_index :beta_invitations, :invite_code
    add_index :beta_invitations, :inviter_id
  end

  def self.down
    remove_index :beta_invitations, :inviter_id
    remove_index :beta_invitations, :invite_code
    drop_table :beta_invitations
  end
end
