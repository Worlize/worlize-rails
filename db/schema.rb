# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20140501190951) do

  create_table "app_instances", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "app_id"
    t.integer  "user_id"
    t.integer  "room_id"
    t.integer  "gifter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "app_instances", ["guid"], :name => "index_app_instances_on_guid"
  add_index "app_instances", ["room_id"], :name => "index_app_instances_on_room_id"
  add_index "app_instances", ["user_id"], :name => "index_app_instances_on_user_id"

  create_table "apps", :force => true do |t|
    t.integer  "creator_id"
    t.string   "guid",        :limit => 36
    t.string   "name",        :limit => 64
    t.string   "tagline"
    t.text     "description"
    t.text     "help"
    t.string   "icon"
    t.string   "app"
    t.integer  "width",       :limit => 8
    t.integer  "height",      :limit => 8
    t.boolean  "active",                    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "apps", ["creator_id"], :name => "index_apps_on_creator_id"
  add_index "apps", ["guid"], :name => "index_apps_on_guid"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token"
    t.string   "profile_url"
    t.string   "display_name"
    t.string   "profile_picture"
  end

  add_index "authentications", ["provider", "uid"], :name => "index_authentications_on_provider_and_uid", :unique => true
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "avatar_instances", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "avatar_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gifter_id"
  end

  add_index "avatar_instances", ["avatar_id"], :name => "index_avatar_instances_on_avatar_id"
  add_index "avatar_instances", ["guid"], :name => "index_avatar_instances_on_guid"
  add_index "avatar_instances", ["user_id"], :name => "index_avatar_instances_on_user_id"

  create_table "avatars", :force => true do |t|
    t.string   "guid",         :limit => 36
    t.integer  "creator_id"
    t.string   "name",         :limit => 64
    t.integer  "offset_x",     :limit => 8
    t.integer  "offset_y",     :limit => 8
    t.integer  "width",        :limit => 8
    t.integer  "height",       :limit => 8
    t.boolean  "active",                     :default => true
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "animated_gif",               :default => false
  end

  add_index "avatars", ["guid"], :name => "index_avatars_on_guid"

  create_table "background_instances", :force => true do |t|
    t.string   "guid",          :limit => 36
    t.integer  "background_id"
    t.integer  "room_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gifter_id"
  end

  add_index "background_instances", ["background_id"], :name => "index_background_instances_on_background_id"
  add_index "background_instances", ["guid"], :name => "index_background_instances_on_guid"
  add_index "background_instances", ["room_id"], :name => "index_background_instances_on_room_id"
  add_index "background_instances", ["user_id"], :name => "index_background_instances_on_user_id"

  create_table "backgrounds", :force => true do |t|
    t.integer  "creator_id"
    t.string   "guid",          :limit => 36
    t.string   "name",          :limit => 64
    t.integer  "width",         :limit => 8
    t.integer  "height",        :limit => 8
    t.boolean  "active",                      :default => true
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "do_not_delete",               :default => false
  end

  add_index "backgrounds", ["guid"], :name => "index_backgrounds_on_guid"

  create_table "banned_image_fingerprints", :force => true do |t|
    t.integer  "dct_fingerprint", :limit => 8, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "banned_image_fingerprints", ["dct_fingerprint"], :name => "index_banned_image_fingerprints_on_dct_fingerprint"

  create_table "banned_ips", :force => true do |t|
    t.integer  "user_id"
    t.integer  "ip"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.text     "reason"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "banned_ips", ["ip"], :name => "index_banned_ips_on_ip", :unique => true

  create_table "beta_codes", :force => true do |t|
    t.string   "code"
    t.integer  "signups_allotted"
    t.string   "campaign_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "beta_codes", ["code"], :name => "index_beta_codes_on_code"

  create_table "beta_invitations", :force => true do |t|
    t.integer  "inviter_id"
    t.string   "name"
    t.string   "email"
    t.string   "invite_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "beta_code_id"
  end

  add_index "beta_invitations", ["invite_code"], :name => "index_beta_invitations_on_invite_code"
  add_index "beta_invitations", ["inviter_id"], :name => "index_beta_invitations_on_inviter_id"

  create_table "client_error_log_items", :force => true do |t|
    t.string   "user_id"
    t.string   "error_type"
    t.integer  "error_id"
    t.string   "name"
    t.text     "message"
    t.text     "stack_trace"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "log_text"
    t.string   "flash_version"
  end

  add_index "client_error_log_items", ["created_at"], :name => "index_client_error_log_items_on_created_at"

  create_table "comments", :force => true do |t|
    t.text     "content"
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "currencies", :force => true do |t|
    t.string "name"
  end

  create_table "event_categories", :force => true do |t|
    t.integer  "position"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_room_options", :force => true do |t|
    t.integer  "position"
    t.string   "name"
    t.integer  "event_theme_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "room_id"
  end

  add_index "event_room_options", ["event_theme_id"], :name => "index_event_room_options_on_event_theme_id"

  create_table "event_themes", :force => true do |t|
    t.integer  "position"
    t.integer  "event_category_id"
    t.string   "name"
    t.string   "header_graphic"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thumbnail"
    t.string   "header_image"
    t.string   "header_background"
  end

  add_index "event_themes", ["event_category_id"], :name => "index_event_themes_on_event_category_id"

  create_table "events", :force => true do |t|
    t.string   "guid",                 :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "room_id"
    t.integer  "event_theme_id"
    t.integer  "event_room_option_id"
    t.string   "name"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean  "rsvp_notifications",                 :default => true
    t.boolean  "hide_guest_list",                    :default => false
    t.boolean  "private",                            :default => false
    t.string   "facebook_event_id",    :limit => 21
    t.string   "state"
  end

  add_index "events", ["guid"], :name => "index_events_on_guid"
  add_index "events", ["starts_at", "user_id"], :name => "index_events_on_starts_at_and_user_id"
  add_index "events", ["user_id"], :name => "index_events_on_user_id"

  create_table "gifts", :force => true do |t|
    t.string   "guid",          :limit => 36
    t.string   "giftable_type"
    t.integer  "giftable_id"
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gifts", ["giftable_type", "giftable_id"], :name => "index_gifts_on_giftable_type_and_giftable_id"
  add_index "gifts", ["guid"], :name => "index_gifts_on_guid"
  add_index "gifts", ["recipient_id"], :name => "index_gifts_on_recipient_id"

  create_table "global_options", :force => true do |t|
    t.integer  "initial_avatar_slots"
    t.integer  "initial_prop_slots"
    t.integer  "initial_background_slots"
    t.integer  "initial_in_world_object_slots"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "image_assets", :force => true do |t|
    t.string   "name"
    t.string   "image"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "image_fingerprints", :force => true do |t|
    t.integer "fingerprintable_id",                :null => false
    t.string  "fingerprintable_type",              :null => false
    t.integer "dct_fingerprint",      :limit => 8, :null => false
  end

  add_index "image_fingerprints", ["fingerprintable_type", "fingerprintable_id"], :name => "fingerprintable_index", :unique => true

  create_table "in_world_object_instances", :force => true do |t|
    t.string   "guid",               :limit => 36
    t.integer  "in_world_object_id"
    t.integer  "user_id"
    t.integer  "room_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gifter_id"
  end

  add_index "in_world_object_instances", ["guid"], :name => "index_in_world_object_instances_on_guid"
  add_index "in_world_object_instances", ["in_world_object_id"], :name => "index_in_world_object_instances_on_in_world_object_id"
  add_index "in_world_object_instances", ["room_id"], :name => "index_in_world_object_instances_on_room_id"
  add_index "in_world_object_instances", ["user_id"], :name => "index_in_world_object_instances_on_user_id"

  create_table "in_world_objects", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "creator_id"
    t.string   "name",       :limit => 64
    t.integer  "offset_x",   :limit => 8
    t.integer  "offset_y",   :limit => 8
    t.integer  "width",      :limit => 8
    t.integer  "height",     :limit => 8
    t.boolean  "active",                   :default => true
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "in_world_objects", ["guid"], :name => "index_in_world_objects_on_guid"

  create_table "locker_slot_prices", :force => true do |t|
    t.string   "slot_kind"
    t.integer  "bucks_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "marketplace_carousel_items", :force => true do |t|
    t.integer "marketplace_featured_item_id"
    t.integer "marketplace_category_id"
    t.integer "position"
  end

  create_table "marketplace_categories", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "marketplace_theme_id"
    t.string   "name"
    t.integer  "position",             :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subcategory_list",     :default => ""
  end

  add_index "marketplace_categories", ["parent_id"], :name => "index_marketplace_categories_on_parent_id"

  create_table "marketplace_creators", :force => true do |t|
    t.string  "display_name", :limit => 48
    t.integer "user_id"
    t.text    "about"
    t.string  "first_name"
    t.string  "last_name"
    t.string  "address1"
    t.string  "address2"
    t.string  "city"
    t.string  "state"
    t.string  "zipcode"
    t.string  "phone"
  end

  add_index "marketplace_creators", ["display_name"], :name => "index_marketplace_creators_on_display_name", :length => {"display_name"=>36}
  add_index "marketplace_creators", ["user_id"], :name => "index_marketplace_creators_on_user_id"

  create_table "marketplace_featured_items", :force => true do |t|
    t.integer  "marketplace_category_id"
    t.boolean  "include_in_carousel",                    :default => false
    t.integer  "position",                               :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "carousel_image"
    t.string   "carousel_thumbnail_image"
    t.integer  "creator_id"
    t.boolean  "active",                                 :default => false
    t.string   "item_type"
    t.integer  "featured_item_id"
    t.string   "featured_item_type",       :limit => 64
  end

  add_index "marketplace_featured_items", ["featured_item_id", "featured_item_type"], :name => "index_on_item_id_and_type"
  add_index "marketplace_featured_items", ["marketplace_category_id", "item_type"], :name => "index_on_category_and_type"

  create_table "marketplace_item_giveaway_receipts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "marketplace_item_giveaway_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "marketplace_item_giveaway_receipts", ["marketplace_item_giveaway_id"], :name => "index_marketplace_item_giveaway_id"
  add_index "marketplace_item_giveaway_receipts", ["user_id"], :name => "index_marketplace_item_giveaway_receipts_on_user_id"

  create_table "marketplace_item_giveaways", :force => true do |t|
    t.integer  "promo_program_id"
    t.integer  "marketplace_item_id"
    t.string   "name"
    t.text     "description"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "marketplace_item_giveaways", ["date"], :name => "index_marketplace_item_giveaways_on_date"
  add_index "marketplace_item_giveaways", ["marketplace_item_id"], :name => "index_marketplace_item_giveaways_on_marketplace_item_id"
  add_index "marketplace_item_giveaways", ["promo_program_id"], :name => "index_marketplace_item_giveaways_on_promo_program_id"

  create_table "marketplace_items", :force => true do |t|
    t.integer  "marketplace_category_id"
    t.integer  "item_id"
    t.string   "item_type"
    t.integer  "marketplace_creator_id"
    t.integer  "marketplace_theme_id"
    t.string   "copyright"
    t.string   "name"
    t.text     "description"
    t.boolean  "on_sale",                 :default => false
    t.integer  "price"
    t.integer  "currency_id",             :default => 1
    t.integer  "purchase_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "marketplace_license_id"
    t.boolean  "archived",                :default => false
  end

  add_index "marketplace_items", ["created_at"], :name => "index_marketplace_items_on_created_at"
  add_index "marketplace_items", ["item_type", "item_id"], :name => "index_marketplace_items_on_item_type_and_item_id"
  add_index "marketplace_items", ["marketplace_category_id"], :name => "index_marketplace_items_on_marketplace_category_id"

  create_table "marketplace_licenses", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "details_link"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "marketplace_tag_contexts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "marketplace_themes", :force => true do |t|
    t.string   "name"
    t.text     "css"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "paypal_transaction_id"
    t.integer  "virtual_currency_product_id"
    t.decimal  "amount",                                   :precision => 10, :scale => 2
    t.string   "currency",                    :limit => 3,                                :default => "USD"
    t.string   "comment"
    t.datetime "created_at"
  end

  add_index "payments", ["user_id"], :name => "index_payments_on_user_id"

  create_table "paypal_transactions", :force => true do |t|
    t.string   "txn_type",                      :limit => 48
    t.string   "custom_value"
    t.string   "txn_id",                        :limit => 19
    t.string   "receipt_id",                    :limit => 32
    t.string   "address_country",               :limit => 64
    t.string   "address_city",                  :limit => 40
    t.string   "address_country_code",          :limit => 2
    t.string   "address_name",                  :limit => 128
    t.string   "address_state",                 :limit => 40
    t.string   "address_status",                :limit => 12
    t.string   "address_street",                :limit => 200
    t.string   "address_zip",                   :limit => 20
    t.string   "contact_phone",                 :limit => 20
    t.string   "first_name",                    :limit => 64
    t.string   "last_name",                     :limit => 64
    t.string   "payer_business_name",           :limit => 127
    t.string   "payer_email",                   :limit => 87
    t.string   "payer_id",                      :limit => 13
    t.decimal  "auth_amount",                                  :precision => 10, :scale => 2
    t.datetime "auth_exp"
    t.string   "auth_id",                       :limit => 19
    t.string   "auth_status",                   :limit => 32
    t.decimal  "exchange_rate",                                :precision => 12, :scale => 6
    t.string   "invoice",                       :limit => 127
    t.string   "item_number",                   :limit => 127
    t.string   "mc_currency",                   :limit => 3
    t.decimal  "mc_fee",                                       :precision => 10, :scale => 2
    t.decimal  "mc_gross",                                     :precision => 10, :scale => 2
    t.decimal  "mc_handling",                                  :precision => 10, :scale => 2
    t.decimal  "mc_shipping",                                  :precision => 10, :scale => 2
    t.boolean  "payer_paypal_account_verified",                                               :default => false
    t.datetime "payment_date"
    t.string   "payment_status",                :limit => 32
    t.string   "payment_type",                  :limit => 10
    t.string   "pending_reason",                :limit => 32
    t.string   "protection_eligibility",        :limit => 32
    t.integer  "quantity"
    t.string   "reason_code",                   :limit => 32
    t.decimal  "remaining_settle",                             :precision => 10, :scale => 2
    t.decimal  "settle_amount",                                :precision => 10, :scale => 2
    t.string   "settle_currency",               :limit => 3
    t.decimal  "shipping",                                     :precision => 10, :scale => 2
    t.string   "shipping_method",               :limit => 32
    t.decimal  "tax",                                          :precision => 10, :scale => 2
    t.string   "transaction_entity"
    t.datetime "case_creation_date"
    t.string   "case_id",                       :limit => 16
    t.string   "case_type",                     :limit => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "paypal_transactions", ["txn_id"], :name => "index_paypal_transactions_on_txn_id"

  create_table "permalinks", :force => true do |t|
    t.string   "link",          :limit => 40
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permalinks", ["link"], :name => "index_permalinks_on_link", :unique => true
  add_index "permalinks", ["linkable_type", "linkable_id"], :name => "index_permalinks_on_linkable_type_and_linkable_id"

  create_table "promo_programs", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "dialog_css"
    t.string   "mode"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prop_instances", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "prop_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gifter_id"
  end

  add_index "prop_instances", ["guid"], :name => "index_prop_instances_on_guid"
  add_index "prop_instances", ["prop_id"], :name => "index_prop_instances_on_prop_id"
  add_index "prop_instances", ["user_id"], :name => "index_prop_instances_on_user_id"

  create_table "props", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.integer  "creator_id"
    t.string   "name",       :limit => 64
    t.integer  "offset_x",   :limit => 8
    t.integer  "offset_y",   :limit => 8
    t.integer  "width",      :limit => 8
    t.integer  "height",     :limit => 8
    t.boolean  "active",                   :default => true
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "props", ["guid"], :name => "index_props_on_guid"

  create_table "public_worlds", :force => true do |t|
    t.integer  "world_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "public_worlds", ["world_id"], :name => "index_public_worlds_on_world_id"

  create_table "registrations", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "twitter"
    t.string   "beta_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "developer",  :default => false
    t.string   "company"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "registrations", ["email"], :name => "index_registrations_on_email"

  create_table "rooms", :force => true do |t|
    t.string   "guid"
    t.string   "name"
    t.integer  "world_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.boolean  "drop_zone",               :default => false
    t.boolean  "hidden",                  :default => false
    t.boolean  "no_direct_entry",         :default => false
    t.integer  "max_occupancy",           :default => 20
    t.boolean  "allow_cascade_when_full", :default => true
    t.boolean  "moderators_only",         :default => false
  end

  add_index "rooms", ["guid"], :name => "index_rooms_on_guid"
  add_index "rooms", ["world_id"], :name => "index_rooms_on_world_id"

  create_table "sharing_links", :force => true do |t|
    t.string   "code"
    t.integer  "user_id"
    t.integer  "room_id"
    t.datetime "expires_at"
    t.integer  "visits",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sharing_links", ["code"], :name => "index_sharing_links_on_code"
  add_index "sharing_links", ["room_id"], :name => "index_sharing_links_on_room_id"
  add_index "sharing_links", ["user_id"], :name => "index_sharing_links_on_user_id"

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

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "cover_image"
    t.string   "profile_image"
    t.text     "about"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "user_restrictions", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "world_id"
    t.datetime "expires_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "global",                     :default => false
    t.string   "reason",     :limit => 1024
  end

  add_index "user_restrictions", ["expires_at"], :name => "index_user_restrictions_on_expires_at"
  add_index "user_restrictions", ["user_id", "expires_at"], :name => "index_user_restrictions_on_user_id_and_expires_at"
  add_index "user_restrictions", ["world_id", "user_id", "expires_at"], :name => "index_user_restrictions_on_world_id_and_user_id_and_expires_at"

  create_table "users", :force => true do |t|
    t.string   "guid",                  :limit => 36
    t.string   "username",              :limit => 36,                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                                                       :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                                           :null => false
    t.string   "single_access_token",                                         :null => false
    t.string   "perishable_token",                                            :null => false
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip",      :limit => 15
    t.string   "last_login_ip"
    t.integer  "failed_login_count"
    t.integer  "login_count"
    t.boolean  "admin",                               :default => false
    t.string   "twitter"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birthday"
    t.string   "state",                               :default => "new_user"
    t.integer  "background_slots"
    t.integer  "avatar_slots"
    t.integer  "prop_slots"
    t.integer  "in_world_object_slots"
    t.integer  "inviter_id"
    t.integer  "beta_code_id"
    t.boolean  "accepted_tos",                        :default => false
    t.boolean  "suspended",                           :default => false
    t.boolean  "developer",                           :default => false
    t.boolean  "newsletter_optin",                    :default => true
    t.datetime "password_changed_at"
    t.integer  "app_slots"
    t.datetime "username_changed_at"
    t.string   "login_name"
  end

  add_index "users", ["current_login_ip"], :name => "index_users_on_current_login_ip"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["guid"], :name => "index_users_on_guid"
  add_index "users", ["login_name"], :name => "index_users_on_login_name", :unique => true
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token", :unique => true
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token", :unique => true
  add_index "users", ["single_access_token"], :name => "index_users_on_single_access_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "virtual_currency_products", :force => true do |t|
    t.string   "guid"
    t.integer  "position"
    t.string   "name"
    t.text     "description"
    t.integer  "coins_to_add"
    t.integer  "bucks_to_add"
    t.string   "currency",     :limit => 3
    t.decimal  "price",                     :precision => 10, :scale => 2
    t.boolean  "archived",                                                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "virtual_currency_products", ["guid"], :name => "index_virtual_currency_products_on_guid"

  create_table "virtual_financial_transactions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "marketplace_item_id"
    t.integer  "payment_id"
    t.integer  "virtual_currency_product_id"
    t.integer  "kind"
    t.integer  "coins_amount"
    t.integer  "bucks_amount"
    t.string   "comment"
    t.datetime "created_at"
  end

  add_index "virtual_financial_transactions", ["marketplace_item_id"], :name => "index_virtual_financial_transactions_on_marketplace_item_id"
  add_index "virtual_financial_transactions", ["user_id"], :name => "index_virtual_financial_transactions_on_user_id"

  create_table "worlds", :force => true do |t|
    t.string   "guid",       :limit => 36
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "rating",                   :default => "Not Rated"
  end

  add_index "worlds", ["guid"], :name => "index_worlds_on_guid"
  add_index "worlds", ["user_id"], :name => "index_worlds_on_user_id"

end
