class CreateEventThemes < ActiveRecord::Migration
  def self.up
    create_table :event_themes do |t|
      t.integer :order
      t.references :event_category
      t.string :name
      t.string :header_graphic
      t.timestamps
    end
    
    add_index :event_themes, :event_category_id
  end

  def self.down
    drop_table :event_themes
  end
end