class RemoveAviaryFieldsFromAvatarInstances < ActiveRecord::Migration
  def up
    remove_column :avatar_instances, :aviary_guid
    remove_column :avatar_instances, :edit_guid
  end

  def down
    add_column :avatar_instances, :edit_guid, :string, :limit => 36
    add_column :avatar_instances, :aviary_guid, :string, :limit => 36
                         
    AvatarInstance.reset_column_information
    AvatarInstance.find_each do |ai|
      ai.update_attribute(:edit_guid, Guid.new.to_s)
    end
  end
end
