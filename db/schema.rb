# This file is auto-generated from the current state of the database. Instead 
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your 
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100823010212) do

  create_table "avatar_instances", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "avatar_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "avatar_instances", ["guid"], :name => "index_avatar_instances_on_guid"

  create_table "avatars", :force => true do |t|
    t.string   "guid",         :limit => 36
    t.integer  "creator_id"
    t.string   "name",         :limit => 64
    t.integer  "offset_x",     :limit => 8
    t.integer  "offset_y",     :limit => 8
    t.integer  "width",        :limit => 8
    t.integer  "height",       :limit => 8
    t.boolean  "active",                     :default => true
    t.integer  "sale_coins"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sale_bucks"
    t.integer  "return_coins"
    t.boolean  "on_sale",                    :default => false
  end

  add_index "avatars", ["guid"], :name => "index_avatars_on_guid"

  create_table "background_instances", :force => true do |t|
    t.string   "guid",          :limit => 36
    t.integer  "background_id"
    t.integer  "room_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "background_instances", ["guid"], :name => "index_background_instances_on_guid"

  create_table "backgrounds", :force => true do |t|
    t.integer  "creator_id"
    t.string   "guid",         :limit => 36
    t.string   "name",         :limit => 64
    t.integer  "width",        :limit => 8
    t.integer  "height",       :limit => 8
    t.boolean  "active",                     :default => true
    t.integer  "sale_coins"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sale_bucks"
    t.integer  "return_coins"
    t.boolean  "on_sale",                    :default => false
  end

  add_index "backgrounds", ["guid"], :name => "index_backgrounds_on_guid"

  create_table "in_world_object_instances", :force => true do |t|
    t.string   "guid",               :limit => 36
    t.integer  "in_world_object_id"
    t.integer  "user_id"
    t.integer  "room_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "in_world_object_instances", ["guid"], :name => "index_in_world_object_instances_on_guid"

  create_table "in_world_objects", :force => true do |t|
    t.string   "guid",         :limit => 36
    t.integer  "creator_id"
    t.string   "name",         :limit => 64
    t.integer  "offset_x",     :limit => 8
    t.integer  "offset_y",     :limit => 8
    t.integer  "width",        :limit => 8
    t.integer  "height",       :limit => 8
    t.boolean  "active",                     :default => true
    t.integer  "sale_coins"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sale_bucks"
    t.integer  "return_coins"
    t.boolean  "on_sale",                    :default => false
  end

  add_index "in_world_objects", ["guid"], :name => "index_in_world_objects_on_guid"

  create_table "prop_instances", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "prop_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prop_instances", ["guid"], :name => "index_prop_instances_on_guid"

  create_table "props", :force => true do |t|
    t.string   "guid",         :limit => 36
    t.integer  "creator_id"
    t.string   "name",         :limit => 64
    t.integer  "offset_x",     :limit => 8
    t.integer  "offset_y",     :limit => 8
    t.integer  "width",        :limit => 8
    t.integer  "height",       :limit => 8
    t.boolean  "active",                     :default => true
    t.integer  "sale_coins"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sale_bucks"
    t.integer  "return_coins"
    t.boolean  "on_sale",                    :default => false
  end

  add_index "props", ["guid"], :name => "index_props_on_guid"

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

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

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
