class CreateGlobalOptions < ActiveRecord::Migration
  def self.up
    create_table :global_options do |t|
      t.column :initial_avatar_slots, :integer
      t.column :initial_prop_slots, :integer
      t.column :initial_background_slots, :integer
      t.column :initial_in_world_object_slots, :integer
      t.timestamps
    end
    GlobalOptions.create(
      :initial_avatar_slots => 3,
      :initial_prop_slots => 3,
      :initial_background_slots => 1,
      :initial_in_world_object_slots => 3
    )
  end

  def self.down
    drop_table :global_options
  end
end
