class RenameInviterColumnToFixSpellingError < ActiveRecord::Migration
  def self.up
    rename_column :users, :inviter_ide, :inviter_id
  end

  def self.down
    rename_column :users, :inviter_id, :inviter_ide
  end
end
