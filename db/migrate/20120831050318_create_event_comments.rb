class CreateEventComments < ActiveRecord::Migration
  def self.up
    create_table :event_comments do |t|
      t.references :event
      t.references :user
      t.text :text
      t.timestamps
    end
    
    add_index :event_comments, :event_id
  end

  def self.down
    drop_table :event_comments
  end
end