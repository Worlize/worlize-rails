class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.string :username, :length => 36
      t.string :name, :length => 64
      t.timestamps
    end
    add_index :users, :guid
    add_index :users, :username
  end

  def self.down
    drop_table :users
  end
end
