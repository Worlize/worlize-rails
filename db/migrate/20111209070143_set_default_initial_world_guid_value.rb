class SetDefaultInitialWorldGuidValue < ActiveRecord::Migration
  def self.up
    World.initial_template_world_guid = World.first.guid
  end

  def self.down
  end
end
