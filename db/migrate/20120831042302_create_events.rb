class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :guid, :limit => 36
      t.timestamps
      t.references :user
      t.references :room
      t.references :event_theme
      t.references :event_room_option
      t.string :name
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :rsvp_notifications, :default => true
      t.boolean :hide_guest_list, :default => false
      t.boolean :private, :default => false
      t.string :facebook_event_id, :limit => 21
    end
    
    add_index :events, :guid
    add_index :events, [:starts_at, :user_id]
    add_index :events, :user_id
  end

  def self.down
    drop_table :events
  end
end