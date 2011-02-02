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

  create_table "applications", :force => true do |t|
    t.integer  "application_id",   :limit => 8, :default => 0
    t.string   "application_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "checkins", :force => true do |t|
    t.integer  "checkin_id",   :limit => 8, :default => 0
    t.integer  "facebook_id",  :limit => 8, :default => 0
    t.string   "message"
    t.datetime "checkin_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "checkins_users", :force => true do |t|
    t.integer "checkin_id",  :limit => 8, :default => 0
    t.integer "facebook_id", :limit => 8, :default => 0
  end

  create_table "places", :force => true do |t|
    t.integer  "place_id",   :limit => 8,                                 :default => 0
    t.string   "place_name"
    t.decimal  "lat",                     :precision => 20, :scale => 16
    t.decimal  "lng",                     :precision => 20, :scale => 16
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",    :limit => 8, :default => 0
    t.integer  "third_party_id", :limit => 8, :default => 0
    t.string   "access_token"
    t.string   "full_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
