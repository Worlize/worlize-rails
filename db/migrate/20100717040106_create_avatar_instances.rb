class CreateAvatarInstances < ActiveRecord::Migration
  def self.up
    create_table :avatar_instances, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :avatar
      t.references :user
      t.timestamps
    end
    add_index :avatar_instances, :guid
  end

  def self.down
    remove_index :avatar_instances, :guid
    drop_table :avatar_instances
  end
end
