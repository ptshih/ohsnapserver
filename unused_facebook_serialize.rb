def serialize_checkin(checkin)
  puts "serializing checkin with id: #{checkin['id']}"
  c = Checkin.find_or_initialize_by_checkin_id(checkin['id'])
  c.checkin_id = checkin['id']
  c.facebook_id = checkin['from']['id']
  c.place_id = checkin['place']['id']
  c.app_id = checkin.has_key?('application') ? (checkin['application'].nil? ? nil : checkin['application']['id']) : nil
  c.message = checkin.has_key?('message') ? checkin['message'] : nil
  c.created_time = Time.parse(checkin['created_time'].to_s)
  c.save

  # Serialize App
  if checkin.has_key?('application') && !checkin['application'].nil? then
    self.serialize_app(checkin['application'])
  end

  # Serialize Tagged Users
  if checkin.has_key?('tags')
    
    # Serialize Tagged User - for author
    self.serialize_tagged_user(checkin['from'], checkin['id'], checkin['place']['id'])
    
    checkin['tags']['data'].each do |t|
      self.serialize_tagged_user(t, checkin['id'], checkin['place']['id'])
    end
  end

  # Send request for Facebook Place
  # Use a non-blocking HTTP queue here
  # self.find_place_for_place_id(checkin['place']['id'])
end

def serialize_place(place)
  puts "serializing place with id: #{place['id']}"
  
  # Pull parent page alias
  # Example: Get "24-Hour-Fitness" from "http://www.facebook.com/pages/24-Hour-Fitness"
  page_parent_alias = ""
  if !place['link'].nil?
    scan_result = place['link'].scan(/pages\/([^\/]*)/).first
    if !scan_result.nil?
      page_parent_alias = scan_result.first
    end
  end
  
  p = Place.find_or_initialize_by_place_id(place['id'])
  p.place_id = place['id']
  p.name = place['name']
  p.lat = place['location']['latitude']
  p.lng = place['location']['longitude']
  p.street = place['location']['street']
  p.city = place['location']['city']
  p.state = place['location']['state']
  p.country = place['location']['country']
  p.zip = place['location']['zip']
  p.phone = place['phone']
  p.checkins_count = place['checkins'].nil? ? 0 : place['checkins']
  p.like_count = place['likes'].nil? ? 0 : place['likes']
  p.attire = place['attire']
  p.category = place['category']
  p.picture = place['picture']
  p.link = place['link']
  p.page_parent_alias = page_parent_alias
  p.website = place['website']
  p.price_range = place['price_range']
  p.raw_hash = place
  p.expires_at = Time.now + 1.days
  p.save
end


# Create or update tagged friend
def serialize_tagged_user(tagged_user, checkin_id, place_id)
  puts "serializing tagged user #{tagged_user} for checkin: #{checkin_id}"
  t = TaggedUser.find_or_initialize_by_checkin_id(tagged_user['id'])
  t.facebook_id = tagged_user['id']
  t.place_id = place_id
  t.checkin_id = checkin_id
  t.name = tagged_user['name']
  t.save
end

# Create or update app in model/database
def serialize_app(app)
  puts "serializing app with id: #{app['id']}"
  a = App.find_or_initialize_by_app_id(app['id'])
  a.app_id = app['id']
  a.name = app['name']
  a.save
end

# Create or update friend
def serialize_friend(friend, facebook_id, degree)
  puts "serializing friend with id: #{friend['id']}"
  f = Friend.where("facebook_id = #{facebook_id} AND friend_id = #{friend['id']}").limit(1).first
  if f.nil?
    f = Friend.create(
      :facebook_id => facebook_id,
      :friend_id => friend['id'],
      :degree => degree
    )
  end
  return f
end