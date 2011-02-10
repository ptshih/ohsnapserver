module API
  class FacebookApi < Api
    
    # Peter's access token
    @@peter_access_token = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    @@james_access_token = "132514440148709|f09dd88ba268a8727e4f3fd5-645750651|k21j0yXPGxYGbJPd0eOEMTy5ZN4"
    @@tom_access_token = "132514440148709|ddfc7b74179c6fd2f6e081ff-4804606|9SUyWXArEX9LFCAuY3DoFDvhgl0"
    
    @@fb_host = 'https://graph.facebook.com'
    @@peter_id = 548430564
    @@james_id = 645750651
    @@tom_id = 4804606
    
    @@peter_latitude = 37.765223405331
    @@peter_longitude = -122.45003812016
    
    attr_accessor :access_token
    
    def initialize(access_token = nil)
      if access_token.nil? then access_token = @@peter_access_token end
      self.access_token = access_token
    end
    
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
        checkin['tags']['data'].each do |t|
          self.serialize_tagged_user(t, checkin['id'])
        end
      end

      # Send request for Facebook Place
      # Use a non-blocking HTTP queue here
      self.find_place_for_place_id(checkin['place']['id'])
    end
    
    # Create or update tagged friend
    def serialize_tagged_user(tagged_user, checkin_id)
      puts "serializing tagged user #{tagged_user} for checkin: #{checkin_id}"
      t = TaggedUser.find_or_initialize_by_checkin_id(tagged_user['id'])
      t.facebook_id = tagged_user['id']
      t.checkin_id = checkin_id
      t.name = tagged_user['name']
      t.save
    end
    
    # Create or update place in model/database
    def serialize_place(place)
      puts "serializing place with id: #{place['id']}"
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
    def serialize_app(app)
      puts "serializing app with id: #{app['id']}"
      a = App.find_or_initialize_by_app_id(app['id'])
      a.app_id = app['id']
      a.name = app['name']
      a.save
    end
    
    # Create or update user
    def serialize_user(user, access_token = nil)
      u = User.find_or_initialize_by_facebook_id(user['id'])
      if not access_token.nil? then u.access_token = access_token end
      u.facebook_id = user['id']
      u.third_party_id = user['third_party_id']
      u.full_name = user.has_key?('name') ? user['name'] : nil
      u.first_name = user.has_key?('first_name') ? user['first_name'] : nil
      u.last_name = user.has_key?('last_name') ? user['last_name'] : nil
      u.gender = user.has_key?('gender') ? user['gender'] : nil
      u.locale = user.has_key?('locale') ? user['locale'] : nil
      u.verified = user.has_key?('verified') ? user['verified'] : nil
      u.save
      
      return u
    end
    
    # Create or update friend
    def serialize_friend(friend, facebook_id, degree)
      f = Friend.find_or_initialize_by_facebook_id_and_friend_id(facebook_id, friend['id'])
      f.facebook_id = facebook_id
      f.friend_id = friend['id']
      f.degree = degree
            # 
            # f = Friend.where("facebook_id = #{facebook_id} AND friend_id = #{friend['id']}").limit(1).first
            # if not f.nil?
            #   f = Friend.create(
            #     :facebook_id => facebook_id,
            #     :friend_id => friend['id'], 
            #     :degree => degree
            #   )
            # end
      
      return f
    end
    
    def update_last_fetched_checkins(facebook_id)
      u = User.find_by_facebook_id(facebook_id)
      puts "updating #{u} last fetched checkins"
      if not u.nil?
        u.update_attribute('last_fetched_checkins', Time.now)
      end
    end
    
    #
    # API CALLS
    #
    
    # Finds all checkins for one user
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_checkins_for_facebook_id(facebook_id = nil)
      begin
        if facebook_id.nil? then facebook_id = @@peter_id end
          
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
      
        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
      
        response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
      
        # Parse checkins
        parsed_response['data'].each do |checkin|
          self.serialize_checkin(checkin)
        end
        
        # Update last_fetched_checkins timestamp for user
        self.update_last_fetched_checkins(facebook_id)
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
    def find_checkins_for_facebook_id_array(facebook_id_array = nil)
      begin
        if facebook_id_array.nil? then 
          facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
        end
        
        # OLD STYLE BATCHED
        # headers_hash = Hash.new
        # headers_hash['Accept'] = 'application/json'
        # 
        # params_hash = Hash.new
        # params_hash['access_token'] = self.access_token
        # params_hash['ids'] = facebook_id_array.join(',')
        # 
        # response = Typhoeus::Request.get("#{@@fb_host}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        # parsed_response = self.parse_json(response.body)
        
        # WE NEED TO HANDLE ERRORS
        # {"error"=>{"type"=>"OAuthException", "message"=>"(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds."}}
        
        # puts "\n\n\n\n\nPARSED: #{parsed_response}\n\n\n\n\n"
        
        # # Parse checkins for each user
        # parsed_keys = parsed_response.keys
        # parsed_keys.each do |key|
        #   parsed_response[key]['data'].each do |checkin|
        #     self.serialize_checkin(checkin)
        #   end
        # end
        # 
        # # Update last_fetched_checkins timestamp for all users
        # facebook_id_array.each do |facebook_id|
        #   self.update_last_fetched_checkins(facebook_id)
        # end
        
        # END OLD STYLE
        
        # NEW QUEUE STYLE
        # Reason we use this is because each facebook user has a different last_fetched_checkins timestamp
        
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
        
        # Generally, you should be running requests through hydra. Here is how that looks
        hydra = Typhoeus::Hydra.new

        facebook_id_array.each do |facebook_id|
          # Configure Params
          params_hash = Hash.new
          params_hash['access_token'] = self.access_token
          
          # Each person has a different last_fetched_checkins timestamp
          u = User.find_by_facebook_id(facebook_id)
          if not u.last_fetched_checkins.nil? then
            params_hash['since'] = u.last_fetched_checkins.to_i
          end
          
          r = Typhoeus::Request.new("#{@@fb_host}/#{facebook_id}/checkins", :method => :get, :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
          
          # Run this block when the request completes
          r.on_complete do |response|
            parsed_response = self.parse_json(response.body)

            # Parse checkins
            parsed_response['data'].each do |checkin|
              self.serialize_checkin(checkin)
            end

            # Update last_fetched_checkins timestamp for user
            self.update_last_fetched_checkins(facebook_id)
          end
          
          # Add this request to the queue
          hydra.queue r
        end
        
        hydra.run # blocking call to run the queue
        
      rescue => e
        p e.message
        p e.backtrace
        return false
      else
        return true
      end
    end
    
    # https://graph.facebook.com/search?type=checkin&access_token=ACCESS_TOKEN
    # def find_all_checkins
    #   begin
    #     headers_hash = Hash.new
    #     headers_hash['Accept'] = 'application/json'
    #   
    #     params_hash = Hash.new
    #     params_hash['access_token'] = self.access_token
    #     params_hash['type'] = 'checkin'
    #     params_hash['limit'] = '50'
    #   
    #     response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
    #     p response.headers
    #     parsed_response = self.parse_json(response.body)
    #   
    #     # Parse checkins
    #     parsed_response['data'].each do |checkin|
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
    def find_places_near_location(lat = nil, lng = nil, distance = 1000, query = nil)
      begin
        # query is optional
      
        # debug
        if lat.nil? then lat = @@peter_latitude end
        if lng.nil? then lng = @@peter_longitude end
      
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
  
        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        params_hash['type'] = 'place'
        params_hash['center'] = "#{lat},#{lng}"
        params_hash['distance'] = "#{distance.to_i}" # safety force to integer because FBAPI wants int (no decimals)
        if not query.nil?
          params_hash['q'] = "#{query}"
        end
      
        response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
      
        # Serialize Places
        parsed_response['data'].each do |place|
          self.serialize_place(place)
        end
      rescue => e
        p e.message
        p e.backtrace
        return nil
      else
        return parsed_response # temporarily just bypass proxy FB's response
      end
    end
    
    # https://graph.facebook.com/121328401214612?access_token=2227470867%7C2.i5b1iBZNAy0qqtEfcMTGRg__.3600.1296727200-548430564%7Cxm3tEtVeLY9alHMAh-0Us17qpbg
    def find_place_for_place_id(place_id = nil)
      begin
        if place_id.nil? then place_id = 57167660895 end # cafe zoe

        # fields to get
        # feed - all posts/comments on the page
        # photos - photos posted on the page
        # notes - not sure?
        # checkins - shows checkins from friends of current access_token

        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'

        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        # params_hash['fields'] = 'feed,photos,notes,checkins'

        response = Typhoeus::Request.get("#{@@fb_host}/#{place_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
        
        # Serialize Place
        facebook_place = self.serialize_place(parsed_response)
      rescue => e
        p e.message
        p e.backtrace
        return nil
      else
        return facebook_place
      end
    end
    
    # Finds friends for a single facebook id
    # https://graph.facebook.com/me/friends?fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    def find_friends_for_facebook_id(facebook_id = nil)
      begin
        if facebook_id.nil? then facebook_id = @@peter_id end
          
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
      
        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
      
        response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
      
        # Parse friends
        parsed_response['data'].each do |friend|
          self.serialize_user(friend)
          self.serialize_friend(friend, facebook_id, 1)
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
    def find_friends_for_facebook_id_array(facebook_id_array = nil)
      begin
        if facebook_id_array.nil? then 
          facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
        end
        
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'

        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
        params_hash['ids'] = facebook_id_array.join(',')

        response = Typhoeus::Request.get("#{@@fb_host}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)

        # Parse friends for each user
        parsed_keys = parsed_response.keys
        parsed_keys.each do |key|
          parsed_response[key]['data'].each do |friend|
            self.serialize_user(friend)
            self.serialize_friend(friend, key.to_i, 1)
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
    
    def find_user_for_facebook_id(facebook_id = nil)
      begin
        if facebook_id.nil? then facebook_id = @@peter_id end
          
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
      
        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'
      
        response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
      
        # Parse user
        facebook_user = self.serialize_user(parsed_response)
      rescue => e
        p e.message
        p e.backtrace
        return nil
      else
        return facebook_user
      end
    end
    
    def find_user_for_facebook_access_token
      begin          
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
      
        params_hash = Hash.new
        params_hash['access_token'] = self.access_token
        params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'
      
        response = Typhoeus::Request.get("#{@@fb_host}/me", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
        parsed_response = self.parse_json(response.body)
        
        facebook_user = self.serialize_user(parsed_response, access_token)
      rescue => e
        p e.message
        p e.backtrace
        return nil
      else
        return facebook_user
      end
    end
    
  end
end