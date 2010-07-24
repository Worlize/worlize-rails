class AddIndexToBackgrounds < ActiveRecord::Migration
  def self.up
    add_index :backgrounds, :guid
  end

  def self.down
    remove_index :backgrounds, :guid
  end
end
