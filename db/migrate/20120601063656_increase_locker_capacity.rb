class IncreaseLockerCapacity < ActiveRecord::Migration
  def self.up
    User.update_all(
      :prop_slots => 10000,
      :avatar_slots => 10000,
      :in_world_object_slots => 10000,
      :background_slots => 10000,
      :app_slots => 10000
    )
  end

  def self.down
  end
end
