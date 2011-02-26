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
  end

  add_index "checkins", ["checkin_id"], :name => "idx_checkin_id", :unique => true
  add_index "checkins", ["facebook_id"], :name => "idx_facebook_id"

  create_table "checkins_users", :force => true do |t|
    t.integer "checkin_id",  :limit => 8, :default => 0
    t.integer "facebook_id", :limit => 8, :default => 0
  end

  add_index "checkins_users", ["checkin_id"], :name => "idx_checkin_id"

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

  create_table "places", :force => true do |t|
    t.integer  "place_id",       :limit => 8,                                 :default => 0
    t.integer  "yelp_id",        :limit => 8,                                 :default => 0
    t.integer  "gowalla_id",     :limit => 8,                                 :default => 0
    t.string   "name"
    t.decimal  "lat",                         :precision => 20, :scale => 16
    t.decimal  "lng",                         :precision => 20, :scale => 16
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zip"
    t.string   "phone"
    t.integer  "checkins_count", :limit => 8,                                 :default => 0
    t.integer  "like_count",     :limit => 8,                                 :default => 0
    t.string   "attire"
    t.string   "website"
    t.string   "price_range"
    t.string   "raw_hash"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tagged_users", :force => true do |t|
    t.integer "checkin_id",  :limit => 8, :default => 0
    t.integer "facebook_id", :limit => 8, :default => 0
    t.string  "name"
  end

  add_index "tagged_users", ["checkin_id"], :name => "idx_checkin_id"
  add_index "tagged_users", ["facebook_id"], :name => "idx_facebook_id"

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",           :limit => 8,                               :default => 0
    t.string   "third_party_id"
    t.string   "access_token"
    t.string   "full_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "locale"
    t.boolean  "verified", :default => false
    t.decimal  "fetch_progress",                     :precision => 3, :scale => 2
    t.datetime "last_fetched_checkins"
    t.datetime "last_fetched_friends"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["facebook_id"], :name => "idx_facebook_id", :unique => true

  create_table "yelp", :force => true do |t|
    t.string   "yelp_id"
    t.integer  "place_id",     :limit => 8,                                 :default => 0
    t.string   "name"
    t.string   "phone"
    t.integer  "review_count"
    t.decimal  "lat",                       :precision => 20, :scale => 16
    t.decimal  "lng",                       :precision => 20, :scale => 16
    t.string   "raw_hash"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "yelp_reviews", :force => true do |t|
    t.string   "yelp_review_pid"
    t.integer  "yelp_id",         :limit => 8, :default => 0
    t.string   "excerpt"
    t.integer  "rating",                       :default => 0
    t.datetime "time_created"
    t.string   "user_name"
    t.string   "user_id"
    t.string   "raw_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "yelps", :force => true do |t|
    t.string   "yelp_pid"
    t.integer  "place_id",     :limit => 8,                                 :default => 0
    t.string   "name"
    t.string   "phone"
    t.integer  "review_count"
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zip"
    t.decimal  "lat",                       :precision => 20, :scale => 16
    t.decimal  "lng",                       :precision => 20, :scale => 16
    t.string   "raw_hash"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "kupos", :force => true do |t|
    t.integer  "facebook_id", :limit => 8, :default => 0
    t.integer  "referee_id", :limit => 8, :default => 0
    t.integer  "place_id", :limit => 8, :default => 0
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.boolean  "is_referral", :default => false
    t.datetime "referred_at"
    t.datetime "completed_at"
  end

end
