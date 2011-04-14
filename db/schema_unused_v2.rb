create_table "apps", :force => true do |t|
  t.integer  "app_id",     :limit => 8, :default => 0
  t.string   "name"
  t.datetime "created_at"
  t.datetime "updated_at"
end

add_index "apps", ["app_id"], :name => "idx_app_id", :unique => true

  t.string   "yelp_pid"
add_index "places", ["yelp_pid"], :name => "idx_yelp_pid"

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
