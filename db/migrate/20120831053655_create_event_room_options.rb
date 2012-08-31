class CreateEventRoomOptions < ActiveRecord::Migration
  def self.up
    create_table :event_room_options do |t|
      t.integer :order
      t.string :name
      t.references :event_theme
      t.references :room_id
      t.timestamps
    end
    
    add_index :event_room_options, :event_theme_id
  end

  def self.down
    drop_table :event_room_options
  end
end