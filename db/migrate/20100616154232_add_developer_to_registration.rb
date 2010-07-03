class AddDeveloperToRegistration < ActiveRecord::Migration
  def self.up
    add_column :registrations, :developer, :boolean, :default => false
  end

  def self.down
    remove_column :registrations, :developer
  end
end
