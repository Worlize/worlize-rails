# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100628010435) do

  create_table "registrations", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "twitter"
    t.string   "beta_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "developer",  :default => false
    t.string   "company"
  end

  create_table "rooms", :force => true do |t|
    t.string   "guid"
    t.string   "name"
    t.integer  "world_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rooms", ["guid"], :name => "index_rooms_on_guid"
  add_index "rooms", ["world_id"], :name => "index_rooms_on_world_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "guid",                :limit => 36
    t.string   "username"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                             :null => false
    t.string   "crypted_password",                  :null => false
    t.string   "password_salt",                     :null => false
    t.string   "persistence_token",                 :null => false
    t.string   "single_access_token",               :null => false
    t.string   "perishable_token",                  :null => false
    t.datetime "last_login_at"
    t.string   "last_login_ip"
    t.integer  "failed_login_count"
    t.integer  "login_count"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["guid"], :name => "index_users_on_guid"
  add_index "users", ["username"], :name => "index_users_on_username"

  create_table "worlds", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "worlds", ["guid"], :name => "index_worlds_on_guid"
  add_index "worlds", ["user_id"], :name => "index_worlds_on_user_id"

end
