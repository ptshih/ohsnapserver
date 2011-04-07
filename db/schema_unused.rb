create_table "checkin_comments", :force => true do |t|
  t.integer  "checkin_id",   :limit => 8, :default => 0
  t.integer  "facebook_id",  :limit => 8, :default => 0
  t.string   "full_name"
  t.string   "message"
  t.datetime "created_time"
end

add_index "checkin_comments", ["checkin_id", "facebook_id"], :name => "idx_checkin_id", :unique => true

create_table "checkin_likes", :force => true do |t|
  t.integer "checkin_id",  :limit => 8,   :default => 0
  t.integer "facebook_id", :limit => 8,   :default => 0
  t.string  "full_name",   :limit => 100
end

add_index "checkin_likes", ["checkin_id", "facebook_id"], :name => "idx_checkin_id", :unique => true


create_table "gowallas", :force => true do |t|
  t.integer  "gowalla_id",     :limit => 8,                                 :default => 0
  t.integer  "place_id",       :limit => 8,                                 :default => 0
  t.string   "name"
  t.integer  "checkins_count"
  t.decimal  "lat",                         :precision => 20, :scale => 16
  t.decimal  "lng",                         :precision => 20, :scale => 16
  t.datetime "expires_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end

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
  t.integer "likes",                           :default => 0
end

add_index "pages", ["id"], :name => "id_UNIQUE", :unique => true
add_index "pages", ["page_alias"], :name => "page_alias_UNIQUE", :unique => true