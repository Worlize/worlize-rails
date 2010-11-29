class AddPurchasedLockerSlotCountsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :background_slots, :integer
    add_column :users, :avatar_slots, :integer
    add_column :users, :prop_slots, :integer
    add_column :users, :in_world_object_slots, :integer
    User.all.each do |user|
      user.update_attributes(
        :background_slots => [user.background_instances.count, 1].max,
        :avatar_slots => [user.avatar_instances.count, 3].max,
        :prop_slots => [user.prop_instances.count, 3].max,
        :in_world_object_slots => [user.in_world_object_instances.count, 3].max
      )
    end
  end

  def self.down
    remove_column :users, :in_world_object_slots
    remove_column :users, :prop_slots
    remove_column :users, :avatar_slots
    remove_column :users, :background_slots
  end
end
