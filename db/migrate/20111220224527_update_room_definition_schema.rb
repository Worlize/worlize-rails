class UpdateRoomDefinitionSchema < ActiveRecord::Migration
  def self.up
    Room.all.each { |r| r.room_definition.room = r; r.room_definition.save }
  end

  def self.down
  end
end
