class BaseSchema < ActiveRecord::Migration
  def self.up
    create_table "applications", :force => true do |t|
      t.integer  "application_id", :limit => 8, :default => 0
      t.string   "application_name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "checkins", :force => true do |t|
      t.integer  "checkin_id",     :limit => 8, :default => 0
      t.integer  "facebook_id",    :limit => 8, :default => 0
      t.string   "message"
      t.datetime "checkin_time"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "places", :force => true do |t|
      t.integer  "place_id",       :limit => 8, :default => 0
      t.string   "place_name"
      t.decimal  "lat",            :precision => 15, :scale => 11
      t.decimal  "lng",            :precision => 15, :scale => 11
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

    create_table "checkins_users", :force => true do |t|
      t.integer  "checkin_id",     :limit => 8, :default => 0
      t.integer  "facebook_id",    :limit => 8, :default => 0
    end
  end

  def self.down
    drop_table "applications"
    drop_table "checkins"
    drop_table "places"
    drop_table "users"
    drop_table "checkins_users"
  end
end
