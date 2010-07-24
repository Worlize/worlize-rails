class CreateBackgroundInstances < ActiveRecord::Migration
  def self.up
    create_table :background_instances, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :background
      t.references :room
      t.references :user
      t.timestamps
    end
    add_index :background_instances, :guid
  end

  def self.down
    remove_index :background_instances, :guid
    drop_table :background_instances
  end
end
