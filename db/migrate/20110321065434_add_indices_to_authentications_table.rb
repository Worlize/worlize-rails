class AddIndicesToAuthenticationsTable < ActiveRecord::Migration
  def self.up
    add_index :authentications, ["provider", "uid"], :name => "index_authentications_on_provider_and_uid", :unique => true
  end

  def self.down
    remove_index :authentications, :name => "index_authentications_on_provider_and_uid"
  end
end
