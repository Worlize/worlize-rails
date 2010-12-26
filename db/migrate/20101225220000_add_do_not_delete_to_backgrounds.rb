class AddDoNotDeleteToBackgrounds < ActiveRecord::Migration
  def self.up
    add_column :backgrounds, :do_not_delete, :boolean, :default => false
  end

  def self.down
    remove_column :backgrounds, :do_not_delete
  end
end
