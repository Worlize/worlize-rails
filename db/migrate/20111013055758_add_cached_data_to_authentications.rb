class AddCachedDataToAuthentications < ActiveRecord::Migration
  def self.up
    add_column :authentications, :display_name, :string
    add_column :authentications, :profile_picture, :string
  end

  def self.down
    remove_column :authentications, :profile_picture
    remove_column :authentications, :display_name
  end
end