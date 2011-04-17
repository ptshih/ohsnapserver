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

ActiveRecord::Schema.define(:version => 20110202082319) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.text     "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "users", :force => true do |t|
    t.integer  "facebook_id",                   :limit => 8,                                 :default => 0
    t.string   "third_party_id"
    t.integer  "twitter_id"
    t.string   "twitter_name"
    t.string   "twitter_screen_name"
    t.string   "access_token"
    t.string   "facebook_access_token"
    t.string   "twitter_access_token"
    t.string   "name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "locale"
    t.boolean  "verified",                                                                   :default => false
    t.datetime "last_fetched_friends"
    t.datetime "last_fetched_feed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "joined_at"
    t.decimal  "last_loc_lat",                               :precision => 20, :scale => 16
    t.decimal  "last_loc_lng",                               :precision => 20, :scale => 16
    t.datetime "last_loc_at"
    t.integer  "last_kupo"
  end

  add_index "users", ["facebook_id"], :name => "idx_facebook_id", :unique => true

  create_table "friendships", :force => true do |t|
    t.integer "facebook_id", :limit => 8, :default => 0
    t.integer "friend_id",   :limit => 8, :default => 0
    t.string  "friend_name"
  end

  add_index "friendships", ["facebook_id", "friend_id"], :name => "idx_unique_facebook_id_and_friend_id", :unique => true
  add_index "friendships", ["facebook_id"], :name => "idx_facebook_id"
  add_index "friendships", ["friend_id"], :name => "idx_friend_id"
  
  create_table "events", :force => true do |t|
    t.string   "tag"
    t.string   "name"
    t.boolean  "is_private", :default => false
    t.integer  "last_kupo_id"
    t.decimal  "last_loc_lat",                               :precision => 20, :scale => 16
    t.decimal  "last_loc_lng",                               :precision => 20, :scale => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  add_index "events", ["tag"], :name => "idx_tag"
  
  create_table "events_users", :id => false, :force => true do |t|
    t.integer "user_id", :limit => 8, :default => 0
    t.integer "event_id",   :limit => 8, :default => 0
    t.boolean "is_active", :default => true
  end
  
  add_index "events_users", ["user_id", "event_id"], :name => "idx_unique_user_id_and_event_id", :unique => true

  create_table "kupos", :force => true do |t|
    t.string   "source"
    t.integer  "event_id",           :limit => 8, :default => 0
    t.integer  "user_id",           :limit => 8, :default => 0
    t.integer  "facebook_place_id",           :limit => 8
    t.integer  "facebook_checkin_id",         :limit => 8
    t.string   "message"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.boolean  "has_photo",                       :default => false
    t.boolean  "has_video",                       :default => false
    t.decimal  "lat",                               :precision => 20, :scale => 16
    t.decimal  "lng",                               :precision => 20, :scale => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kupos", ["user_id"], :name => "idx_user_id"
  add_index "kupos", ["event_id"], :name => "idx_event_id"
  add_index "kupos", ["facebook_checkin_id"], :name => "idx_facebook_checkin_id"
  add_index "kupos", ["facebook_place_id"], :name => "idx_facebook_place_id"
  add_index "kupos", ["has_photo"], :name => "idx_has_photo"
  add_index "kupos", ["has_video"], :name => "idx_has_video"
  
  create_table "checkins", :force => true do |t|
    t.integer  "facebook_checkin_id",   :limit => 8, :default => 0
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.integer  "facebook_place_id",           :limit => 8, :default => 0
    t.string   "facebook_app_name"
    t.string   "tagged_facebook_names"
    t.string   "tagged_facebook_ids"
    t.datetime "created_time"
  end

  add_index "checkins", ["facebook_checkin_id"], :name => "idx_facebook_checkin_id", :unique => true
  add_index "checkins", ["facebook_id"], :name => "idx_facebook_id"
  add_index "checkins", ["facebook_place_id"], :name => "idx_facebook_place_id"

  create_table "places", :force => true do |t|
    t.integer  "facebook_place_id",          :limit => 8,                                   :default => 0
    t.string   "name"
    t.decimal  "lat",                              :precision => 20, :scale => 16
    t.decimal  "lng",                              :precision => 20, :scale => 16
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zip"
    t.string   "phone"
    t.integer  "checkin_count",    :limit => 8,                                   :default => 0
    t.integer  "like_count",        :limit => 8,                                   :default => 0
    t.string   "attire"
    t.string   "category",          :limit => 100
    t.string   "picture",           :limit => 200
    t.string   "link",              :limit => 100
    t.string   "website"
    t.string   "price_range"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "places", ["lat", "lng"], :name => "idx_lat_lng"
  add_index "places", ["facebook_place_id"], :name => "idx_facebook_place_id", :unique => true
  
  create_table "logs", :force => true do |t|
    t.datetime "event_timestamp",                                                 :null => false
    t.datetime "session_starttime",                                               :null => false
    t.string   "udid",              :limit => 55
    t.string   "device_model",      :limit => 50
    t.string   "system_name",       :limit => 10
    t.string   "system_version",    :limit => 10
    t.string   "app_version",       :limit => 10
    t.integer  "user_id",       :limit => 8
    t.integer  "connection_type"
    t.string   "language",          :limit => 15
    t.string   "locale",            :limit => 15
    t.decimal  "lat",                             :precision => 20, :scale => 16
    t.decimal  "lng",                             :precision => 20, :scale => 16
    t.string   "action_type",       :limit => 30
    t.decimal  "var1",                            :precision => 16, :scale => 8
    t.integer  "var2",              :limit => 8
    t.string   "var3",              :limit => 50
    t.string   "var4",              :limit => 50
  end

end
