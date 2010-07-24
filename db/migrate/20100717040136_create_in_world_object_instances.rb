class CreateInWorldObjectInstances < ActiveRecord::Migration
  def self.up
    create_table :in_world_object_instances, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :in_world_object
      t.references :user
      t.references :room
      t.timestamps
    end
    add_index :in_world_object_instances, :guid
  end

  def self.down
    remove_index :in_world_object_instances, :guid
    drop_table :in_world_object_instances
  end
end
