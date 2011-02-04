module API
  class FacebookApi < Api
    @@fbHost = 'https://graph.facebook.com'
    @@peterId = 548430564
    @@jamesId = 645750651
    @@tomId = 4804606
    
    @@peterLatitude = 37.765223405331
    @@peterLongitude = -122.45003812016
    
    # Peter's access token
    @@peterAccessToken = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    @@jamesAccessToken = "132514440148709|f09dd88ba268a8727e4f3fd5-645750651|k21j0yXPGxYGbJPd0eOEMTy5ZN4"
    @@tomAccessToken = "132514440148709|ddfc7b74179c6fd2f6e081ff-4804606|9SUyWXArEX9LFCAuY3DoFDvhgl0"
    
    
    # Just some notes here
    # 1. A single user signs on
    # 2. We fetch the user's friends list
    # 3. Create User entries for user and friends
    # 4. Create Friend entries for all friends for the user
    # 5. We fetch all checkins for the user and all his friends
    # 6. When we parse checkins, we also need to parse tagged_users (which may or may not be his friend)
    # 7. We don't want to create User entries for tagged_users who don't already exist because they are not friends (no access), we only have their name/id
    # 8. Tagged users who are not friends will show up in a checkin, but will be un-interactable (need to check in the API, our DB won't represent this)
    
    # Create or update checkin in model/database
    def self.serialize_checkin(checkin)
      c = Checkin.find_or_initialize_by_checkin_id(checkin['id'])
      c.checkin_id = checkin['id']
      c.facebook_id = checkin['from']['id']
      c.place_id = checkin['place']['id']
      c.app_id = checkin['application']['id']
      c.message = checkin['message'].nil? ? nil : checkin['message']
      c.created_time = Time.parse(checkin['created_time'])
      c.save
      
      # Serialize App
      self.serialize_app(checkin['application'])
      
      # Serialize Tagged Users
      if checkin.has_key?('tags')
        checkin['tags']['data'].each do |t|
          self.serialize_tagged_user(t, checkin['id'])
        end
      end

      # Send request for Facebook Place
      # Use a non-blocking HTTP queue here
      self.find_place_for_place_id(checkin['place']['id'])
    end
    
    # Create or update tagged friend
    def self.serialize_tagged_user(taggedUser, checkinId)
      t = TaggedUser.find_or_initialize_by_checkin_id(taggedUser['id'])
      t.facebook_id = taggedUser['id']
      t.checkin_id = checkinId
      t.name = taggedUser['name']
      t.save
    end
    
    # Create or update place in model/database
    def self.serialize_place(place)
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
       p.raw_hash = place
       p.expires_at = Time.now + 1.days
       p.save
    end
    
    # Create or update app in model/database
    def self.serialize_app(app)
      a = App.find_or_initialize_by_app_id(app['id'])
      a.app_id = app['id']
      a.name = app['name']
      a.save
    end
    
    # Create or update user
    def self.serialize_user(user)
      u = User.find_or_initialize_by_facebook_id(user['id'])
      u.facebook_id = user['id']
      u.third_party_id = user['third_party_id']
      u.full_name = user.has_key?('name') ? user['name'] : nil
      u.first_name = user.has_key?('first_name') ? user['first_name'] : nil
      u.last_name = user.has_key?('last_name') ? user['last_name'] : nil
      u.gender = user.has_key?('gender') ? user['gender'] : nil
      u.locale = user.has_key?('locale') ? user['locale'] : nil
      u.verified = user.has_key?('verified') ? user['verified'] : nil
      u.save
    end
    
    # Create or update friend
    def self.serialize_friend(friend, facebookId, degree)
      if Friend.where("facebook_id = #{facebookId} AND friend_id = #{friend['id']}").empty?
        f = Friend.create(
          :facebook_id => facebookId,
          :friend_id => friend['id'], 
          :degree => degree
        )
      end
    end
    
    def self.update_last_fetched_checkins(facebookId)
      u = User.find_by_facebook_id(facebookId)
      if not u.nil?
        u.update_attribute('last_fetched_checkins', Time.now)
      end
    end
    
    #
    # API CALLS
    #
    
    # Finds all checkins for one user
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def self.find_checkins_for_facebook_id(facebookId = nil)
      begin
        if facebookId.nil? then facebookId = @@peterId end
          
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'
      
        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
      
        response = Typhoeus::Request.get("#{@@fbHost}/#{facebookId}/checkins", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
      
        # Parse checkins
        parsedResponse['data'].each do |checkin|
          self.serialize_checkin(checkin)
        end
        
        # Update last_fetched_checkins timestamp for user
        self.update_last_fetched_checkins(facebookId)
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # Finds all checkins for an array of user ids
    # https://graph.facebook.com/checkins?ids=4804606,548430564,645750651&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def self.find_checkins_for_facebook_id_array(facebookIdArray = nil)
      begin
        if facebookIdArray.nil? then 
          facebookIdArray = [@@peterId, @@tomId, @@jamesId]
        end
        
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'

        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['ids'] = facebookIdArray.join(',')

        response = Typhoeus::Request.get("#{@@fbHost}/checkins", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)

        # Parse checkins for each user
        parsedKeys = parsedResponse.keys
        parsedKeys.each do |key|
          parsedResponse[key]['data'].each do |checkin|
            self.serialize_checkin(checkin)
          end
        end
        
        # Update last_fetched_checkins timestamp for all users
        facebookIdArray.each do |facebookId|
          self.update_last_fetched_checkins(facebookId)
        end
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # https://graph.facebook.com/search?type=checkin&access_token=ACCESS_TOKEN
    # def self.find_all_checkins
    #   begin
    #     headersHash = Hash.new
    #     headersHash['Accept'] = 'application/json'
    #   
    #     paramsHash = Hash.new
    #     paramsHash['access_token'] = @@peterAccessToken
    #     paramsHash['type'] = 'checkin'
    #     paramsHash['limit'] = '50'
    #   
    #     response = Typhoeus::Request.get("#{@@fbHost}/search", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
    #     p response.headers
    #     parsedResponse = self.parse_json(response.body)
    #   
    #     # Parse checkins
    #     parsedResponse['data'].each do |checkin|
    #       self.serialize_checkin(checkin)
    #     end
    #   rescue => e
    #     p e.message
    #     p e.backtrace
    #     return false
    #   else
    #     return true
    #   end
    # end
    
    # https://graph.facebook.com/search?q=pizza&type=place&center=lat,long&distance=1000
    def self.find_places_near_location(lat = nil, lng = nil, distance = 1000, query = nil)
      begin
        # query is optional
      
        # debug
        if lat.nil? then lat = @@peterLatitude end
        if lng.nil? then lng = @@peterLongitude end
      
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'
  
        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['type'] = 'place'
        paramsHash['center'] = "#{lat},#{lng}"
        paramsHash['distance'] = "#{distance}"
        if not query.nil?
          paramsHash['q'] = "#{query}"
        end
      
        response = Typhoeus::Request.get("#{@@fbHost}/search", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
      
        # Serialize Places
        parsedResponse['data'].each do |place|
          self.serialize_place(place)
        end
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # https://graph.facebook.com/121328401214612?access_token=2227470867%7C2.i5b1iBZNAy0qqtEfcMTGRg__.3600.1296727200-548430564%7Cxm3tEtVeLY9alHMAh-0Us17qpbg
    def self.find_place_for_place_id(placeId = nil)
      begin
        if placeId.nil? then placeId = 57167660895 end # cafe zoe

        # fields to get
        # feed - all posts/comments on the page
        # photos - photos posted on the page
        # notes - not sure?
        # checkins - shows checkins from friends of current access_token

        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'

        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        # paramsHash['fields'] = 'feed,photos,notes,checkins'

        response = Typhoeus::Request.get("#{@@fbHost}/#{placeId}", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
        
        # Serialize Place
        self.serialize_place(parsedResponse)
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # Finds friends for a single facebook id
    # https://graph.facebook.com/me/friends?fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def self.find_friends_for_facebook_id(facebookId = nil)
      begin
        if facebookId.nil? then facebookId = @@peterId end
          
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'
      
        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
      
        response = Typhoeus::Request.get("#{@@fbHost}/#{facebookId}/friends", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
      
        # Parse friends
        parsedResponse['data'].each do |friend|
          self.serialize_user(friend)
          self.serialize_friend(friend, facebookId, 1)
        end
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # Finds friends for an array of facebook ids
    # https://graph.facebook.com/friends?ids=4804606,548430564,645750651&fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def self.find_friends_for_facebook_id_array(facebookIdArray = nil, degree = 1)
      begin
        if facebookIdArray.nil? then 
          facebookIdArray = [@@peterId, @@tomId, @@jamesId]
        end
        
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'

        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
        paramsHash['ids'] = facebookIdArray.join(',')

        response = Typhoeus::Request.get("#{@@fbHost}/friends", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)

        # Parse friends for each user
        parsedKeys = parsedResponse.keys
        parsedKeys.each do |key|
          parsedResponse[key]['data'].each do |friend|
            self.serialize_user(friend)
            self.serialize_friend(friend, key.to_i, degree)
          end
        end
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    def self.find_user_for_facebook_id(facebookId = nil)
      begin
        if facebookId.nil? then facebookId = @@peterId end
          
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'
      
        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'
      
        response = Typhoeus::Request.get("#{@@fbHost}/#{facebookId}", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
      
        # Parse user
        self.serialize_user(parsedResponse)
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
  end
end