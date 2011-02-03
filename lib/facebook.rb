module API
  class Facebook < Api
    @@fbHost = 'https://graph.facebook.com'
    @@peterId = 548430564
    
    @@peterLatitude = 37.765223405331
    @@peterLongitude = -122.45003812016
    
    # Peter's access token
    @@peterAccessToken = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    
    def self.find_checkins_for_facebook_id(facebookId = @@peterId)
      headersHash = Hash.new
      headersHash['Accept'] = 'application/json'
      headersHash['Accept-Encoding'] = 'gzip'
      
      paramsHash = Hash.new
      paramsHash['access_token'] = @@peterAccessToken
      
      response = Typhoeus::Request.get("#{@@fbHost}/#{facebookId}/checkins", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
      p response.headers_hash
      p response.body
    end
    
    # https://graph.facebook.com/search?type=checkin&access_token=ACCESS_TOKEN
    def self.find_all_checkins
      headersHash = Hash.new
      headersHash['Accept'] = 'application/json'
      headersHash['Accept-Encoding'] = 'gzip'
      
      paramsHash = Hash.new
      paramsHash['access_token'] = @@peterAccessToken
      paramsHash['type'] = 'checkin'
      
      response = Typhoeus::Request.get("#{@@fbHost}/search", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
      p response.headers_hash
      p response.body
    end
    
    # https://graph.facebook.com/search?q=pizza&type=place&center=lat,long&distance=1000
    def self.find_places_near_location(lat = nil, lng = nil, distance = 1000, query = nil)
      # query is optional
      
      # debug
      lat = @@peterLatitude
      lng = @@peterLongitude
      
      headersHash = Hash.new
      headersHash['Accept'] = 'application/json'
      headersHash['Accept-Encoding'] = 'gzip'
  
      paramsHash = Hash.new
      paramsHash['access_token'] = @@peterAccessToken
      paramsHash['type'] = 'place'
      paramsHash['center'] = "#{lat},#{lng}"
      paramsHash['distance'] = "#{distance}"
      if not query.nil?
        paramsHash['q'] = "#{query}"
      end
      
      response = Typhoeus::Request.get("#{@@fbHost}/search", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
      p response.headers_hash
      p response.body
      
    end
    
    # https://graph.facebook.com/121328401214612?access_token=2227470867%7C2.i5b1iBZNAy0qqtEfcMTGRg__.3600.1296727200-548430564%7Cxm3tEtVeLY9alHMAh-0Us17qpbg
    def self.find_place_for_place_id(placeId = nil)
      if placeId.nil?
        placeId = 57167660895 # cafe zoe
      end
      
      # fields to get
      # feed
      # photos
      # notes
      # checkins

      headersHash = Hash.new
      headersHash['Accept'] = 'application/json'
      headersHash['Accept-Encoding'] = 'gzip'
  
      paramsHash = Hash.new
      paramsHash['access_token'] = @@peterAccessToken
      paramsHash['fields'] = 'feed,photos,notes,checkins'
      
      response = Typhoeus::Request.get("#{@@fbHost}/#{placeId}", :params => paramsHash, :headers => headersHash, :disable_ssl_peer_verification => true)
      p response.headers_hash
      p response.body   
      
    end
    
  end
end