class CreateGifts < ActiveRecord::Migration
  def self.up
    create_table :gifts do |t|
      t.column :guid, :string, :limit => 36
      t.column :giftable_type, :string
      t.column :giftable_id, :integer
      t.column :sender_id, :integer
      t.column :recipient_id, :integer
      t.column :note, :string
      t.timestamps
    end
    
    add_index :gifts, :guid
    add_index :gifts, :recipient_id
    
    add_column :avatar_instances, :gifter_id, :integer
    add_column :background_instances, :gifter_id, :integer
    add_column :in_world_object_instances, :gifter_id, :integer
    add_column :prop_instances, :gifter_id, :integer
  end

  def self.down
    remove_column :prop_instances, :gifter_id
    remove_column :in_world_object_instances, :gifter_id
    remove_column :background_instances, :gifter_id
    remove_column :avatar_instances, :gifter_id
    drop_table :gifts
  end
end
