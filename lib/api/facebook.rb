module API
  class Facebook < Api
    @@fbHost = 'https://graph.facebook.com'
    @@peterId = 548430564
    @@jamesId = 645750651
    
    @@peterLatitude = 37.765223405331
    @@peterLongitude = -122.45003812016
    
    # Peter's access token
    @@peterAccessToken = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    @@jamesAccessToken = "132514440148709|f09dd88ba268a8727e4f3fd5-645750651|k21j0yXPGxYGbJPd0eOEMTy5ZN4"
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    
    # Create or update checkin in model/database
    def self.serialize_checkin(checkin)
      c = Checkin.find_or_initialize_by_checkin_id(checkin['id'])
      c.checkin_id = checkin['id']
      c.facebook_id = checkin['from']['id']
      c.place_id = checkin['place']['id']
      c.app_id = checkin['application']['id']
      c.checkin_message = checkin['message'].nil? ? nil : checkin['message']
      c.checkin_time = Time.parse(checkin['created_time'])
      c.save
      
      # Serialize App
      self.serialize_app(checkin['application'])
      
      # Send request for Facebook Place
      # Use a non-blocking HTTP queue here
      self.find_place_for_place_id(checkin['place']['id'])
    end
    
    # Create or update place in model/database
    def self.serialize_place(place)
       p = Place.find_or_initialize_by_place_id(place['id'])
       p.place_id = place['id']
       p.place_name = place['name']
       p.place_lat = place['location']['latitude']
       p.place_lng = place['location']['longitude']
       p.place_street = place['location']['street']
       p.place_city = place['location']['city']
       p.place_state = place['location']['state']
       p.place_country = place['location']['country']
       p.place_zip = place['location']['zip']
       p.raw_hash = place
       p.expires_at = Time.now + 1.days
       p.save
    end
    
    # Create or update app in model/database
    def self.serialize_app(app)
      a = App.find_or_initialize_by_app_id(app['id'])
      a.app_id = app['id']
      a.app_name = app['name']
      a.save
    end
      
    def self.find_checkins_for_facebook_id(facebookId = @@jamesId)
      begin
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
      rescue
        return false
      else
        return true
      end
    end
    
    # https://graph.facebook.com/search?type=checkin&access_token=ACCESS_TOKEN
    def self.find_all_checkins
      begin
        headersHash = Hash.new
        headersHash['Accept'] = 'application/json'
      
        paramsHash = Hash.new
        paramsHash['access_token'] = @@peterAccessToken
        paramsHash['type'] = 'checkin'
      
        response = Typhoeus::Request.get("#{@@fbHost}/search", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
        parsedResponse = self.parse_json(response.body)
      
        # Parse checkins
        parsedResponse['data'].each do |checkin|
          self.serialize_checkin(checkin)
        end
      rescue
        return false
      else
        return true
      end
    end
    
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
      rescue
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
      rescue
        return false
      else
        return true
      end
    end
  end
end