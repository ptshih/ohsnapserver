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

  create_table "apps", :force => true do |t|
    t.integer  "app_id",     :limit => 8, :default => 0
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "apps", ["app_id"], :name => "idx_app_id", :unique => true

  create_table "checkins", :force => true do |t|
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.integer  "place_id",     :limit => 8, :default => 0
    t.integer  "app_id",       :limit => 8, :default => 0
    t.string   "message"
    t.datetime "created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "kupo_id",      :limit => 8, :default => 0
  end

  add_index "checkins", ["checkin_id"], :name => "idx_checkin_id", :unique => true
  add_index "checkins", ["facebook_id"], :name => "idx_facebook_id"

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

  create_table "friends", :force => true do |t|
    t.integer "facebook_id", :limit => 8, :default => 0
    t.integer "friend_id",   :limit => 8, :default => 0
    t.integer "degree",                   :default => 0
  end

  add_index "friends", ["facebook_id", "friend_id"], :name => "idx_unique_facebook_id_and_friend_id", :unique => true
  add_index "friends", ["facebook_id"], :name => "idx_facebook_id"
  add_index "friends", ["friend_id"], :name => "idx_friend_id"

  create_table "kupos", :force => true do |t|
    t.integer  "facebook_id",        :limit => 8, :default => 0
    t.integer  "place_id",           :limit => 8, :default => 0
    t.integer  "checkin_id",         :limit => 8
    t.integer  "kupo_type"
    t.string   "comment"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.boolean  "has_photo",                       :default => false
    t.boolean  "has_video",                       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kupos", ["checkin_id"], :name => "idx_checkin_id"
  add_index "kupos", ["facebook_id", "place_id"], :name => "idx_fbid_place_id"
  add_index "kupos", ["facebook_id"], :name => "idx_facebook_id"
  add_index "kupos", ["has_photo"], :name => "idx_has_photo"
  add_index "kupos", ["has_video"], :name => "idx_has_video"
  add_index "kupos", ["place_id"], :name => "idx_place_id"

  create_table "logs", :force => true do |t|
    t.datetime "event_timestamp",                                                 :null => false
    t.datetime "session_starttime",                                               :null => false
    t.string   "udid",              :limit => 55
    t.string   "device_model",      :limit => 50
    t.string   "system_name",       :limit => 10
    t.string   "system_version",    :limit => 10
    t.string   "app_version",       :limit => 10
    t.integer  "facebook_id",       :limit => 8
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

  create_table "places", :force => true do |t|
    t.integer  "place_id",          :limit => 8,                                   :default => 0
    t.string   "yelp_pid"
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
  add_index "places", ["place_id"], :name => "idx_place_id", :unique => true
  add_index "places", ["yelp_pid"], :name => "idx_yelp_pid"

  create_table "tagged_users", :force => true do |t|
    t.integer "facebook_id", :limit => 8, :default => 0
    t.integer "checkin_id",  :limit => 8, :default => 0
    t.integer "place_id",    :limit => 8
    t.string  "name"
  end

  add_index "tagged_users", ["checkin_id", "facebook_id"], :name => "idx_checkin_id_and_facebook_id", :unique => true
  add_index "tagged_users", ["checkin_id"], :name => "idx_checkin_id"
  add_index "tagged_users", ["facebook_id"], :name => "idx_facebook_id"
  add_index "tagged_users", ["place_id"], :name => "idx_place_id"

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",                   :limit => 8,                                 :default => 0
    t.string   "third_party_id"
    t.string   "full_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "locale"
    t.boolean  "verified",                                                                   :default => false
    t.datetime "last_fetched_checkins"
    t.datetime "last_fetched_friends"
    t.datetime "last_fetched_friends_checkins"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "joined_at"
    t.decimal  "last_loc_lat",                               :precision => 20, :scale => 16
    t.decimal  "last_loc_lng",                               :precision => 20, :scale => 16
    t.datetime "last_loc_at"
    t.integer  "last_kupo"
  end

  add_index "users", ["facebook_id"], :name => "idx_facebook_id", :unique => true

  create_table "yelp_categories", :force => true do |t|
    t.string "category"
  end

  add_index "yelp_categories", ["category"], :name => "idx_category", :unique => true

  create_table "yelp_categories_yelps", :id => false, :force => true do |t|
    t.integer "yelp_id"
    t.integer "yelp_category_id"
  end

  add_index "yelp_categories_yelps", ["yelp_category_id"], :name => "idx_yelp_category_id"
  add_index "yelp_categories_yelps", ["yelp_id"], :name => "idx_yelp_id"

  create_table "yelp_images", :force => true do |t|
    t.string "yelp_pid"
    t.string "url"
  end

  add_index "yelp_images", ["url"], :name => "idx_url", :unique => true
  add_index "yelp_images", ["yelp_pid"], :name => "idx_yelp_pid"

  create_table "yelp_reviews", :force => true do |t|
    t.string "yelp_pid"
    t.string "rating"
    t.string "reviewer_name"
    t.string "reviewer_image"
    t.string "reviewer_profile"
    t.text   "text"
  end

  add_index "yelp_reviews", ["yelp_pid"], :name => "idx_yelp_id"

  create_table "yelp_terms", :force => true do |t|
    t.string "term"
  end

  add_index "yelp_terms", ["term"], :name => "idx_term", :unique => true

  create_table "yelp_terms_yelps", :id => false, :force => true do |t|
    t.integer "yelp_id"
    t.integer "yelp_term_id"
  end

  add_index "yelp_terms_yelps", ["yelp_id"], :name => "idx_yelp_id"
  add_index "yelp_terms_yelps", ["yelp_term_id"], :name => "idx_yelp_term_id"

  create_table "yelps", :force => true do |t|
    t.string   "yelp_pid",                                                                 :null => false
    t.integer  "place_id",     :limit => 8,                                 :default => 0
    t.decimal  "lat",                       :precision => 20, :scale => 16
    t.decimal  "lng",                       :precision => 20, :scale => 16
    t.string   "name"
    t.string   "rating"
    t.integer  "review_count"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "yelps", ["place_id"], :name => "idx_place_id"
  add_index "yelps", ["yelp_pid"], :name => "idx_yelp_pid", :unique => true

  create_table "tokens", :force => true do |t|
    t.integer "facebook_id", :limit => 8, :default => 0
    t.string "access_token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tokens", ["access_token"], :name => "idx_access_token", :unique => true
    
end
