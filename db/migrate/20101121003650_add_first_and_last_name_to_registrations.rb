class AddFirstAndLastNameToRegistrations < ActiveRecord::Migration
  def self.up
    add_column :registrations, :first_name, :string
    add_column :registrations, :last_name, :string
    Registration.all.each do |registration|
      name_parts = registration.name.split(' ')
      if name_parts[0]
        registration.first_name = name_parts[0]
      end
      if name_parts.length > 1
        registration.last_name = name_parts[name_parts.length-1]
      end
      registration.save(:validate => false)
    end
  end

  def self.down
    remove_column :registrations, :last_name
    remove_column :registrations, :first_name
  end
end
