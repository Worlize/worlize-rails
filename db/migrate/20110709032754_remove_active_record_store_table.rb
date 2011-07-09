class RemoveActiveRecordStoreTable < ActiveRecord::Migration
  def self.up
    drop_table :sessions
  end

  def self.down
    create_table "sessions", :force => true do |t|
      t.string   "session_id",                     :null => false
      t.text     "data",       :limit => 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
