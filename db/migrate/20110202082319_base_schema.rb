class BaseSchema < ActiveRecord::Migration
  def self.up
    create_table :apps do |t|
      t.integer  "app_id", :limit => 8, :default => 0
      t.string   "app_name"
      t.timestamps
    end

    create_table :checkins do |t|
      t.integer  "checkin_id",     :limit => 8, :default => 0
      t.integer  "facebook_id",    :limit => 8, :default => 0
      t.integer  "place_id",    :limit => 8, :default => 0
      t.integer  "application_id",    :limit => 8, :default => 0
      t.string   "checkin_message"
      t.datetime "checkin_time"
      t.timestamps
    end

    create_table :places do |t|
      t.integer  "place_id",       :limit => 8, :default => 0
      t.integer  "yelp_id",       :limit => 8, :default => 0
      t.integer  "gowalla_id",       :limit => 8, :default => 0
      t.string   "place_name"
      t.decimal  "place_lat",            :precision => 20, :scale => 16
      t.decimal  "place_lng",            :precision => 20, :scale => 16
      t.datetime "expires_at"
      t.timestamps
    end
    
    create_table :yelps do |t|
      t.integer  "yelp_id",       :limit => 8, :default => 0
      t.integer  "place_id",       :limit => 8, :default => 0
      t.string   "yelp_name"
      t.string   "yelp_phone"
      t.integer  "review_count"
      t.decimal  "yelp_lat",            :precision => 20, :scale => 16
      t.decimal  "yelp_lng",            :precision => 20, :scale => 16
      t.timestamps
    end
    
    create_table :gowallas do |t|
      t.integer  "gowalla_id",       :limit => 8, :default => 0
      t.integer  "place_id",       :limit => 8, :default => 0
      t.string   "gowalla_name"
      t.integer  "checkins_count"
      t.decimal  "gowalla_lat",            :precision => 20, :scale => 16
      t.decimal  "gowalla_lng",            :precision => 20, :scale => 16
      t.timestamps
    end

    create_table :users do |t|
      t.integer  "facebook_id",    :limit => 8, :default => 0
      t.integer  "third_party_id", :limit => 8, :default => 0
      t.string   "access_token"
      t.string   "full_name"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "gender"
      t.timestamps
    end

    create_table :checkins_users do |t|
      t.integer  "checkin_id",     :limit => 8, :default => 0
      t.integer  "facebook_id",    :limit => 8, :default => 0
    end
  end

  def self.down
    drop_table :applications
    drop_table :checkins
    drop_table :places
    drop_table :yelps
    drop_table :gowallas
    drop_table :users
    drop_table :checkins_users
  end
end
