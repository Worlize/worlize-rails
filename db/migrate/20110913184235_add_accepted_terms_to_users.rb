class AddAcceptedTermsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :accepted_tos, :boolean, :default => false
  end

  def self.down
    remove_column :users, :accepted_tos
  end
end