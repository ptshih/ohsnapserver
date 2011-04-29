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

  create_table "albums", :force => true do |t|
    t.string   "name"
    t.integer  "last_snap_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "albums", ["last_snap_id"], :name => "idx_last_snap_id"
  add_index "albums", ["name"], :name => "idx_name"
  add_index "albums", ["updated_at"], :name => "idx_updated_at"

  create_table "albums_users", :id => false, :force => true do |t|
    t.integer "user_id",  :limit => 8, :default => 0
    t.integer "album_id", :limit => 8, :default => 0
  end

  add_index "albums_users", ["user_id", "album_id"], :name => "idx_unique_user_id_and_album_id", :unique => true

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

  create_table "friendships", :force => true do |t|
    t.integer "user_id",     :limit => 8, :default => 0
    t.integer "friend_id",   :limit => 8, :default => 0
    t.string  "friend_name"
    t.string  "friend_type",              :default => "facebook"
  end

  add_index "friendships", ["friend_id"], :name => "idx_friend_id"
  add_index "friendships", ["user_id", "friend_id"], :name => "idx_unique_user_id_and_friend_id", :unique => true
  add_index "friendships", ["user_id"], :name => "idx_user_id"

  create_table "logs", :force => true do |t|
    t.datetime "event_timestamp",                                                 :null => false
    t.datetime "session_starttime",                                               :null => false
    t.string   "udid",              :limit => 55
    t.string   "device_model",      :limit => 50
    t.string   "system_name",       :limit => 10
    t.string   "system_version",    :limit => 10
    t.string   "app_version",       :limit => 10
    t.integer  "user_id",           :limit => 8
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

  create_table "snap_comments", :force => true do |t|
    t.integer  "album_id",   :limit => 8
    t.integer  "snap_id",    :limit => 8, :default => 0
    t.integer  "user_id",    :limit => 8, :default => 0
    t.string   "message"
    t.datetime "created_at"
  end

  add_index "snap_comments", ["album_id", "created_at"], :name => "idx_album_created"
  add_index "snap_comments", ["snap_id"], :name => "idx_snap_id"
  add_index "snap_comments", ["user_id"], :name => "idx_user_id"

  create_table "snap_likes", :force => true do |t|
    t.integer  "album_id",   :limit => 8
    t.integer  "snap_id",    :limit => 8, :default => 0
    t.integer  "user_id",    :limit => 8, :default => 0
    t.datetime "created_at"
  end

  add_index "snap_likes", ["album_id", "created_at"], :name => "idx_album_created_at"
  add_index "snap_likes", ["album_id", "snap_id", "user_id"], :name => "idx_album_snap_user", :unique => true

  create_table "snaps", :force => true do |t|
    t.integer  "album_id",           :limit => 8,                                 :default => 0
    t.integer  "user_id",            :limit => 8,                                 :default => 0
    t.string   "message"
    t.string   "type",               :limit => 0
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.decimal  "lat",                             :precision => 20, :scale => 16
    t.decimal  "lng",                             :precision => 20, :scale => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "snaps", ["album_id"], :name => "idx_album_id"
  add_index "snaps", ["type"], :name => "idx_type"
  add_index "snaps", ["user_id"], :name => "idx_user_id"

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",           :limit => 8, :default => 0
    t.string   "third_party_id"
    t.string   "access_token"
    t.string   "facebook_access_token"
    t.string   "google_access_token"
    t.string   "picture_url"
    t.string   "email"
    t.string   "name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "locale"
    t.boolean  "verified",                           :default => false
    t.datetime "last_fetched_friends"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "joined_at"
    t.integer  "last_snap_id"
  end

  add_index "users", ["facebook_id"], :name => "idx_facebook_id", :unique => true

end
