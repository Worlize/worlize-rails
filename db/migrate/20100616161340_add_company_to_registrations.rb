class AddCompanyToRegistrations < ActiveRecord::Migration
  def self.up
    add_column :registrations, :company, :string
  end

  def self.down
    remove_column :registrations, :company
  end
end
