class AddGlobalToUserRestrictions < ActiveRecord::Migration
  def self.up
    add_column :user_restrictions, :global, :boolean, :default => false
  end

  def self.down
    remove_column :user_restrictions, :global
  end
end