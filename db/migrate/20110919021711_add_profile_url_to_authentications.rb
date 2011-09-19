class AddProfileUrlToAuthentications < ActiveRecord::Migration
  def self.up
    add_column :authentications, :profile_url, :string
  end

  def self.down
    remove_column :authentications, :profile_url
  end
end