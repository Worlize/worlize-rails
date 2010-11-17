class AddEmailIndexToRegistrations < ActiveRecord::Migration
  def self.up
    add_index :registrations, :email
  end

  def self.down
    remove_index :registrations, :email
  end
end
