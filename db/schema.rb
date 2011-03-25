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

  create_table "checkin_likes", :force => true do |t|
    t.integer "checkin_id",  :limit => 8,   :default => 0
    t.integer "facebook_id", :limit => 8,   :default => 0
    t.string  "full_name",   :limit => 100
  end

  add_index "checkin_likes", ["checkin_id", "facebook_id"], :name => "idx_checkin_id", :unique => true

  create_table "checkin_posts", :primary_key => "post_id", :force => true do |t|
    t.integer  "id",                                       :null => false
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.string   "full_name"
    t.string   "message"
    t.datetime "created_time"
  end

  add_index "checkin_posts", ["checkin_id"], :name => "idx_checkin_id"
  add_index "checkin_posts", ["facebook_id"], :name => "idx_facebook_id"
  add_index "checkin_posts", ["post_id"], :name => "post_id_UNIQUE", :unique => true

  create_table "checkins", :force => true do |t|
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.integer  "place_id",     :limit => 8, :default => 0
    t.integer  "app_id",       :limit => 8, :default => 0
    t.string   "message"
    t.datetime "created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  add_index "friends", ["facebook_id", "friend_id"], :name => "idx_unique_fbid_and_friendid", :unique => true
  add_index "friends", ["facebook_id"], :name => "idx_facebook_id"
  add_index "friends", ["friend_id"], :name => "idx_friend_id"

  create_table "gowallas", :force => true do |t|
    t.integer  "gowalla_id",     :limit => 8,                                 :default => 0
    t.integer  "place_id",       :limit => 8,                                 :default => 0
    t.string   "name"
    t.integer  "checkins_count"
    t.decimal  "lat",                         :precision => 20, :scale => 16
    t.decimal  "lng",                         :precision => 20, :scale => 16
    t.string   "raw_hash"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "kupos", :force => true do |t|
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.integer  "referee_id",   :limit => 8, :default => 0
    t.integer  "place_id",     :limit => 8, :default => 0
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.string  "comment",
    t.string   "photo_file_name",
    t.string   "photo_content_type",
    t.integer  "photo_file_size",
    t.string  "picture_url",
    t.datetime "created_at"
  end

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
    t.string   "var1",              :limit => 50
    t.string   "var2",              :limit => 50
    t.string   "var3",              :limit => 50
    t.string   "var4",              :limit => 50
  end

  create_table "notifications", :force => true do |t|
    t.integer  "sender_id",         :limit => 8,  :default => 0
    t.integer  "receiver_id",       :limit => 8,  :default => 0
    t.string   "notify_type",       :limit => 10
    t.integer  "notify_object_id",  :limit => 8
    t.text     "message"
    t.datetime "send_timestamp",                                 :null => false
    t.datetime "receive_timestamp"
  end

  add_index "notifications", ["notify_type"], :name => "idx_place_id"
  add_index "notifications", ["receiver_id"], :name => "idx_receiver_id"
  add_index "notifications", ["sender_id"], :name => "idx_sender_id"

  create_table "pages", :force => true do |t|
    t.string  "page_alias",       :limit => 100,                :null => false
    t.integer "facebook_id",      :limit => 8
    t.string  "name",             :limit => 50
    t.string  "picture_sq_url",   :limit => 100
    t.string  "picture",          :limit => 200
    t.string  "link",             :limit => 100
    t.string  "category",         :limit => 100
    t.string  "website_url",      :limit => 100
    t.string  "username",         :limit => 100
    t.string  "company_overview"
    t.string  "products"
    t.string  "raw_hash"
    t.integer "likes",                           :default => 0
  end

  add_index "pages", ["id"], :name => "id_UNIQUE", :unique => true
  add_index "pages", ["page_alias"], :name => "page_alias_UNIQUE", :unique => true

  create_table "place_posts", :force => true do |t|
    t.integer  "place_id",          :limit => 8, :default => 0
    t.string   "place_post_id"
    t.string   "post_type"
    t.integer  "from_id",           :limit => 8, :default => 0
    t.string   "from_name"
    t.string   "message"
    t.string   "picture"
    t.string   "link"
    t.string   "name"
    t.datetime "post_created_time"
    t.datetime "post_updated_time"
  end

  add_index "place_posts", ["place_id"], :name => "idx_place_id"
  add_index "place_posts", ["place_post_id"], :name => "uniq_place_post_id", :unique => true

  create_table "places", :force => true do |t|
    t.integer  "place_id",          :limit => 8,                                   :default => 0
    t.string   "yelp_pid"
    t.integer  "gowalla_id",        :limit => 8,                                   :default => 0
    t.string   "name"
    t.decimal  "lat",                              :precision => 20, :scale => 16
    t.decimal  "lng",                              :precision => 20, :scale => 16
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zip"
    t.string   "phone"
    t.integer  "checkins_count",    :limit => 8,                                   :default => 0
    t.integer  "like_count",        :limit => 8,                                   :default => 0
    t.string   "attire"
    t.string   "category",          :limit => 100
    t.string   "picture",           :limit => 200
    t.string   "picture_url",       :limit => 200
    t.string   "link",              :limit => 100
    t.string   "website"
    t.string   "price_range"
    t.string   "raw_hash"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "page_parent_alias", :limit => 45
  end

  add_index "places", ["lat", "lng"], :name => "idx_lat_lng"
  add_index "places", ["place_id"], :name => "idx_place_id", :unique => true
  add_index "places", ["yelp_pid"], :name => "idx_yelp_pid"

  create_table "shares", :force => true do |t|
    t.integer  "checkin_id",  :limit => 8,  :default => 0
    t.integer  "facebook_id", :limit => 8,  :default => 0
    t.integer  "place_id",    :limit => 8,  :default => 0
    t.string   "message",     :limit => 45
    t.datetime "shared_at",                                :null => false
  end

  add_index "shares", ["facebook_id"], :name => "idx_facebook_id"

  create_table "shares_maps", :force => true do |t|
    t.integer  "facebook_id",       :limit => 8, :default => 0
    t.integer  "accept_checkin_id", :limit => 8
    t.datetime "accept_timestamp"
  end

  create_table "tagged_users", :force => true do |t|
    t.integer "checkin_id",  :limit => 8, :default => 0
    t.integer "place_id",    :limit => 8
    t.integer "facebook_id", :limit => 8, :default => 0
    t.string  "name"
  end

  add_index "tagged_users", ["checkin_id", "facebook_id"], :name => "idx_checkinid_and_fbid", :unique => true
  add_index "tagged_users", ["facebook_id"], :name => "idx_facebook_id"
  add_index "tagged_users", ["place_id"], :name => "idx_place_id"

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",           :limit => 8,                               :default => 0
    t.string   "third_party_id"
    t.string   "access_token"
    t.string   "full_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "locale"
    t.boolean  "verified",                                                         :default => false
    t.decimal  "fetch_progress",                     :precision => 3, :scale => 2
    t.datetime "last_fetched_checkins"
    t.datetime "last_fetched_friends"
    t.datetime "created_at"
    t.datetime "updated_at"
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

end
