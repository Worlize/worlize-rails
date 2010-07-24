class CreatePropInstances < ActiveRecord::Migration
  def self.up
    create_table :prop_instances, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :prop
      t.references :user
      t.timestamps
    end
    add_index :prop_instances, :guid
  end

  def self.down
    remove_index :prop_instances, :guid
    drop_table :prop_instances
  end
end
