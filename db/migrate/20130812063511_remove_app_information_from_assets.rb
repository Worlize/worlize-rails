class RemoveAppInformationFromAssets < ActiveRecord::Migration
  def self.up
    ids_to_delete = InWorldObject.where(:kind => 'app').map(&:id)
    InWorldObjectInstance.where(:in_world_object_id => ids_to_delete).delete_all
    InWorldObject.where(:id => ids_to_delete).delete_all
    
    remove_index :avatars, :reviewer_id
    remove_index :backgrounds, :reviewer_id
    remove_index :in_world_objects, :reviewer_id
    
    remove_column :avatars, :reviewer_id
    remove_column :avatars, :requires_approval
    remove_column :avatars, :reviewal_status
    remove_column :avatars, :icon
    remove_column :avatars, :kind
    remove_column :avatars, :app

    remove_column :backgrounds, :reviewer_id
    remove_column :backgrounds, :requires_approval
    remove_column :backgrounds, :reviewal_status
    remove_column :backgrounds, :icon
    remove_column :backgrounds, :kind
    remove_column :backgrounds, :app

    remove_column :in_world_objects, :reviewer_id
    remove_column :in_world_objects, :requires_approval
    remove_column :in_world_objects, :reviewal_status
    remove_column :in_world_objects, :icon
    remove_column :in_world_objects, :kind
    remove_column :in_world_objects, :app
  end

  def self.down
    add_column :in_world_objects, :kind, :string, :default => 'image'
    add_column :in_world_objects, :app, :string
    add_column :in_world_objects, :icon, :string
    add_column :in_world_objects, :requires_approval, :boolean, :default => false
    add_column :in_world_objects, :reviewal_status, :string, :default => 'new'
    add_column :in_world_objects, :reviewer_id, :integer
    
    add_index :in_world_objects, :reviewer_id

    InWorldObject.reset_column_information
    say_with_time("Setting :kind => 'image' on all existing InWorldObjects") do
      InWorldObject.update_all(:kind => 'image')
    end


    add_column :backgrounds, :kind, :string, :default => 'image'
    add_column :backgrounds, :app, :string
    add_column :backgrounds, :icon, :string
    add_column :backgrounds, :requires_approval, :boolean, :default => false
    add_column :backgrounds, :reviewal_status, :string, :default => 'new'
    add_column :backgrounds, :reviewer_id, :integer
    
    add_index :backgrounds, :reviewer_id

    Background.reset_column_information
    say_with_time("Setting :kind => 'image' on all existing Backgrounds") do
      Background.update_all(:kind => 'image')
    end


    add_column :avatars, :kind, :string, :default => 'image'
    add_column :avatars, :app, :string
    add_column :avatars, :icon, :string
    add_column :avatars, :requires_approval, :boolean, :default => false
    add_column :avatars, :reviewal_status, :string, :default => 'new'
    add_column :avatars, :reviewer_id, :integer
    
    add_index :avatars, :reviewer_id
    
    Avatar.reset_column_information
    say_with_time("Setting :kind => 'image' on all existing Avatars") do
      Avatar.update_all(:kind => 'image')
    end
  end
end
