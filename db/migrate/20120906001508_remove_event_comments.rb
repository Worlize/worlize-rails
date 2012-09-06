class RemoveEventComments < ActiveRecord::Migration
  def up
    drop_table :event_comments
  end

  def down
    create_table :event_comments do |t|
      t.references :event
      t.references :user
      t.text :text
      t.timestamps
    end
    
    add_index :event_comments, :event_id
  end
end
