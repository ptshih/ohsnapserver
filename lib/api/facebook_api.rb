module API

  class FacebookApi < Api

    # Peter's access token
    @@peter_access_token = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    @@james_access_token = "132514440148709%257Cf09dd88ba268a8727e4f3fd5-645750651%257Ck21j0yXPGxYGbJPd0eOEMTy5ZN4"
    @@tom_access_token = "132514440148709|ddfc7b74179c6fd2f6e081ff-4804606|9SUyWXArEX9LFCAuY3DoFDvhgl0"
    @@moone_access_token = "132514440148709|22ebfa70b9a561d421c076fe-100002025298734|dJd8XJJg4p67Jh_lRFkkgEHX4Go"
    @@moseven_access_token = "mmMkvl-BKP5IBuW_Tyz3v213LJuYnogIPJP0EE0cvOY.eyJpdiI6IkNMdmF4dVhUSHEyTVFUbUMyamNBeVEifQ.zfvNH4V4mdy9aC8-eACKTVdpUMTN8EpHy-7ehBJmion65onca6xJ6GOvkf5X3PTzlB_sMAnfxp6sDmamlum2WtfMDnX3hbDQR3MFlr9-Uc5kW0T-EBXguC_Bn_4L4W2weSkhQjmxfdnpURgjg8JIZw"

    @@fb_host = 'https://graph.facebook.com'
    @@fb_app_id = '132514440148709'
    @@fb_app_secret = '925b0a280e685631acf466dfea13b154'
    @@fb_app_access_token = '132514440148709|a7Wfkm22IRitMGJSGTUtr1hI7CE'
    @@peter_id = 548430564
    @@james_id = 645750651
    @@tom_id = 4804606
    @@moone_id = 100002025298734

    @@peter_latitude = 37.765223405331
    @@peter_longitude = -122.45003812016

    # attr_accessor :access_token, :hydra

    def initialize(access_token = nil)
      if access_token.nil? then access_token = @@moone_access_token end
      @access_token = access_token

      @hydra = Typhoeus::Hydra.new
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
    # Returns a list of place_ids
    def serialize_checkin_bulk(checkins,createkupos=true)
      create_new_checkin = []
      create_new_tagged_user = []
      create_new_app = []
      place_id_array=[]
      checkin_id_array = []

      # Loop through each checkin
      checkins.each do |checkin|
        # Create new checkin
        checkin_id = checkin['id']
        facebook_id = checkin['from']['id']
        place_id = checkin['place']['id']
        app_id = checkin.has_key?('application') ? (checkin['application'].nil? ? nil : checkin['application']['id']) : nil
        app_name = checkin.has_key?('application') ? (checkin['application'].nil? ? nil : checkin['application']['name']) : nil
        message = checkin.has_key?('message') ? checkin['message'] : nil
        created_time = Time.parse(checkin['created_time'].to_s)

        place_id_array << place_id
        checkin_id_array << checkin_id
        
        create_new_checkin << [checkin_id, facebook_id, place_id, app_id, app_name, message, created_time]
        
        # Create app
        if checkin.has_key?('application') && !checkin['application'].nil? then
          create_new_app << [checkin['application']['id'], checkin['application']['name']]
        end

        #Tagged User - for author
        create_new_tagged_user << [checkin['id'], checkin['place']['id'], checkin['from']['id'], checkin['from']['name']]
        # Create Tagged Users - all other
        if checkin.has_key?('tags')
          checkin['tags']['data'].each do |t|
            create_new_tagged_user << [checkin['id'], checkin['place']['id'], t['id'], t['name']]
          end
        end
      end

      # Set the columns requires for import
      checkin_columns = [:checkin_id, :facebook_id, :place_id, :app_id, :app_name, :message, :created_time]
      tagged_user_columns = [:checkin_id, :place_id, :facebook_id, :name]
      app_columns = [:app_id, :name]

      # Import the data
      Checkin.import checkin_columns, create_new_checkin, :on_duplicate_key_update => [:created_time]
      TaggedUser.import tagged_user_columns, create_new_tagged_user, :on_duplicate_key_update => [:name]

      if !create_new_app.nil?
        App.import app_columns, create_new_app, :on_duplicate_key_update => [:name]
      end

      # Serialize the checkin to a kupo
      if createkupos
        self.serialize_kupo_via_checkin_bulk(checkin_id_array)
      else
        checkins_id_string = checkin_id_array.join(',')
        # Mark the checkin object as having been copied to kupos table
        query = "update checkins
                set kupo_id=1
                where kupo_id =0 and checkin_id in (#{checkins_id_string})"
        mysqlresult = ActiveRecord::Base.connection.execute(query)
      end
      
      return place_id_array
    end
    
    def serialize_kupo_via_checkin_bulk(checkin_id_array)
      
      # Create the kupos ONLY IF it hasn't already been created in kupos table already
      # kupo_type=0 is a checkin
      checkins_id_string = checkin_id_array.join(',')
      query = "insert into kupos
              (facebook_id, place_id, checkin_id, app_name, kupo_type, comment, created_at, updated_at)
              select facebook_id, place_id, checkin_id, app_name, 0, message, created_time, updated_at
              from checkins
              where kupo_id =0 and checkin_id in (#{checkins_id_string})"
      mysqlresult = ActiveRecord::Base.connection.execute(query)
      
      # Mark the checkin object as having been copied to kupos table
      query = "update checkins
              set kupo_id=1
              where kupo_id =0 and checkin_id in (#{checkins_id_string})"
      mysqlresult = ActiveRecord::Base.connection.execute(query)
      
    end

    def serialize_place_bulk(places)
      create_new_place = []
      parsed_keys = places.keys
      parsed_keys.each do |place|
        # Create new place
        place_id = places[place]['id']
        name = places[place]['name']
        lat = places[place]['location']['latitude']
        lng = places[place]['location']['longitude']
        street = places[place]['location']['street']
        city = places[place]['location']['city']
        state = places[place]['location']['state']
        country = places[place]['location']['country']
        zip = places[place]['location']['zip']
        phone = places[place]['phone']
        checkin_count = places[place]['checkins'].nil? ? 0 : places[place]['checkins']
        like_count = places[place]['likes'].nil? ? 0 : places[place]['likes']
        attire = places[place]['attire']
        category = places[place]['category']
        picture = places[place]['picture']
        link = places[place]['link']
        website = places[place]['website']
        price_range = places[place]['price_range']
        expires_at = Time.now + 1.days
        create_new_place << [place_id, name, lat, lng, street, city, state, country, zip, phone, checkin_count, like_count, attire, category, picture, link, website, price_range, expires_at]
      end
      place_columns = [:place_id, :name, :lat, :lng, :street, :city, :state, :country, :zip, :phone,
                       :checkin_count, :like_count, :attire, :category, :picture, :link, :website, :price_range, :expires_at]

      # Notice we are NOT overriding the or inserting into the column picture_url
      Place.import place_columns, create_new_place, :on_duplicate_key_update => [:name, :lat, :lng, :street, :city, :state, :country, :zip, :phone, :checkin_count, :like_count, :attire, :category, :picture, :link, :website, :price_range, :expires_at]

      puts "Serialized #{create_new_place.length} places in bulk."
    end

    # Create or update place in model/database

    # Create or update user
    def serialize_user(user, facebook_access_token = nil)
      # puts "serializing user with id: #{user['id']}"
      u = User.find_or_initialize_by_facebook_id(user['id'])
      u.facebook_id = user['id']
      u.facebook_access_token = facebook_access_token
      u.third_party_id = user['third_party_id']
      u.picture_url = "https://graph.facebook.com/#{user['id']}/picture"
      u.name = user.has_key?('name') ? user['name'] : nil
      u.first_name = user.has_key?('first_name') ? user['first_name'] : nil
      u.last_name = user.has_key?('last_name') ? user['last_name'] : nil
      u.locale = user.has_key?('locale') ? user['locale'] : nil
      u.verified = user.has_key?('verified') ? user['verified'] : nil
      u.save

      return u
    end
    
    def serialize_token(facebook_id, access_token = nil)
      # puts "serialize token: #{facebook_id}, token: #{access_token}"
      a = Token.find_or_initialize_by_access_token(access_token)
      a.access_token = access_token
      a.facebook_id = facebook_id
      a.save
    end

    def serialize_friend_bulk(friends, facebook_id, degree)
      create_new_user = []
      create_new_friend = []
      friend_id_array = []
      friends.each do |friend|
        # New, faster way of bulk inserting in database
        # Create new user
        user_facebook_id = friend['id']
        third_party_id = friend['third_party_id']
        picture_url = "https://graph.facebook.com/#{friend['id']}/picture"
        name = friend.has_key?('name') ? friend['name'] : nil
        first_name = friend.has_key?('first_name') ? friend['first_name'] : nil
        last_name = friend.has_key?('last_name') ? friend['last_name'] : nil
        locale = friend.has_key?('locale') ? friend['locale'] : nil
        verified = friend.has_key?('verified') ? friend['verified'] : nil

        create_new_user << [user_facebook_id, third_party_id, picture_url, name, first_name, last_name, locale, verified]
        create_new_friend << [facebook_id, friend['id'], friend['name']]
        friend_id_array << friend['id']
      end

      user_columns = [:facebook_id, :third_party_id, :picture_url, :name, :first_name, :last_name, :locale, :verified]
      friend_columns = [:facebook_id, :friend_id, :friend_name]

      User.import user_columns, create_new_user, :on_duplicate_key_update => [:name]
      # Friendship.import friend_columns, create_new_friend, :on_duplicate_key_update => [:friend_name]

      friend_id_array_string = friend_id_array.join(',') 
      query = " insert ignore into friendships
                (user_id, friend_id, friend_name)
                select a.id, b.id, b.name
                from users a
                join users b on b.facebook_id in (#{friend_id_array_string})
                where a.facebook_id = #{facebook_id}
              "
      mysqlresult = ActiveRecord::Base.connection.execute(query)

      return friend_id_array
    end

    def last_fetched_feed(user_id)
      puts "updating #{user_id} last fetched feed"
      u = User.find_by_id(user_id)
      if not u.nil?
        u.update_attribute('last_fetched_feed', Time.now)
      end
    end

    def update_last_fetched_friends(facebook_id)
      puts "updating #{facebook_id} last fetched friends"
      u = User.find_by_facebook_id(facebook_id)
      if not u.nil?
        u.update_attribute('last_fetched_friends', Time.now)
      end
    end

    def update_expires_at_place_id(place_id)
      puts "updating #{place_id} last fetched time"
      p = Place.find_by_place_id(place_id)
      if not p.nil?
        p.update_attribute('expires_at', Time.now)
      end
    end
    
    def set_joined_at(facebook_id)
      now_time = Time.now.utc.to_s(:db)
      query = " update users
                set joined_at = '#{now_time}'
                where facebook_id = #{facebook_id} and joined_at is null
              "
      mysqlresult = ActiveRecord::Base.connection.execute(query)
    end

    ###
    ### Error Handling
    ###

    # Returns true if there is an error in the response
    # Returns false if there is no error

    # WE NEED TO HANDLE ERRORS
    # {"error"=>{"type"=>"OAuthException", "message"=>"(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds."}}
    # {"error_code":1,"error_msg":"An unknown error occurred"}
    # {
    #    "error": {
    #       "type": "OAuthException",
    #       "message": "Error validating access token."
    #    }
    # }
    
    # {"error":{"type":"OAuthException","message":"(#1) You are too far away to check in to this place.  Move closer to this place, then try again."}}
    
    # {"error":{"type":"OAuthException","message":"(#2200) callback verification failed: Operation timed out after 6001 milliseconds with 0 bytes received"}}

    # IF we get throttled, spawn a delayed_job and send it off after 10 minutes
    def check_facebook_response_for_errors(response = nil)
      # If the response is nil, we error out
      if response.body.nil?
        Rails.logger.info "\n\n======\n\nEmpty Response From Facebook\n\n=======\n\n"
        return nil
      end

      # puts "\n\n======\n\nPrinting raw response: #{response.body}\n\n=======\n\n"

      # parse the json response
      parsed_response = self.parse_json(response.body)
      
      # read generic error
      if (!parsed_response["error_code"].nil?) || (!parsed_response["error_msg"].nil?)
        Rails.logger.info "\n\n======\n\nFacebook Generic Error Code: #{parsed_response["error_code"]}, Message: #{parsed_response["error_msg"]}\n\n=======\n\n"
        return nil
      end

      # read oauth error
      if (!parsed_response["error"].nil?)
        error_type = parsed_response["error"]["type"]
        error_message = parsed_response["error"]["message"]

        # We got throttled, respond with error
        # Maybe in the future we can queue the request in a delayed job?
        if (error_type == "OAuthException" && error_message == "(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds.")
          Rails.logger.info "\n\n======\n\nWe got THROTTLED by Facebook!!!\n\n=======\n\n"
        elsif (error_type == "OAuthException" && error_message == "Error validating access token.")
          Rails.logger.info "\n\n======\n\nWe got an invalid token: #{@access_token}!!!\n\n=======\n\n"
        else
          Rails.logger.info "\n\n======\n\nFacebook Error Caught: #{parsed_response["error"]}\n\n=======\n\n"
        end
        return nil
      end
        
      return parsed_response
    end

    ###
    ### Checkins
    ###

    # Finds a checkin for ONE checkin_id and serializes
    # API::FacebookApi.new.find_checkin_for_checkin_id(10150278443605565)
    def find_checkin_for_checkin_id(checkin_id = nil, createkupos=true)
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'
      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      response = Typhoeus::Request.get("#{@@fb_host}/#{checkin_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end

      # if there are no recent checkins, don't try to serialize it
      if parsed_response.empty?
        return true
      end

      self.serialize_checkin_bulk([parsed_response],createkupos)

      return true
    end

    # Finds recent checkins for one user and his/her friends
    # This API is used on the absolute first launch (register) so the user can immediately start playing around with the app
    # While we fetch the historical data in the background
    # https://graph.facebook.com/search?type=checkin&fields=id,from,tags,message,place,application,created_time&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    # API::FacebookApi.new.find_recent_checkins_for_facebook_id()
    def find_recent_checkins_for_facebook_id(facebook_id = nil)
      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "START find recent checkins for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['type'] = 'checkin'
      params_hash['fields'] = 'id,from,tags,place,message,likes,comments,application,created_time'
      params_hash['limit'] = 1000 # set this to a really high limit to get all results in one call
      # if !since.nil? then
      #   params_hash['since'] = since.to_i
      # end

      response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end
      
      # if there are no recent checkins, don't try to serialize it
      if parsed_response['data'].empty?
        return true
      end

      place_id_array = Array.new
      
      # Batch parse checkins
      place_id_array = self.serialize_checkin_bulk(parsed_response['data'])

      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array(place_id_array.uniq)
      end

      puts "END find recent checkins for facebook_id: #{facebook_id}"
      
      return true
    end


    # Finds all checkins for one user
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    # API::FacebookApi.new.find_checkins_for_facebook_id(548430564)
    def find_checkins_for_facebook_id(facebook_id = nil, since = nil)
      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "find checkins for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'id,from,tags,place,message,likes,comments,application,created_time'
      params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call
      if !since.nil? then
        params_hash['since'] = since.to_i
      end
      
      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

puts response.body;

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end
      
      # if there are no recent checkins, don't try to serialize it
      if parsed_response['data'].empty?
        return true
      end

      place_id_array = Array.new

      # Batch parse checkins
      place_id_array = self.serialize_checkin_bulk(parsed_response['data'])

      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array(place_id_array.uniq)
      end

      # Update last_fetched_checkins timestamp for user
      self.update_last_fetched_checkins(facebook_id)

      # Correlate unique list of place_ids with yelp places
      # Note: Do in background later
      # if !place_id_array.empty?
      #    puts "Start Yelp correlation"
      #    API::YelpApi.new.correlate_yelp_to_place_with_place_place_id_array(place_id_array.uniq)
      #    puts "End Yelp correlation"
      #  end

      return true

    end
    
    # This is used by the /user/register and /user/session THREADED calls
    def find_checkins_for_facebook_id_array_async(facebook_id = nil, facebook_id_array = nil, since = nil)
      # async call to find_checkins_for_facebook_id_array
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'id,from,tags,place,message,likes,comments,application,created_time'
      params_hash['ids'] = facebook_id_array.join(',')
      params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call
      if !since.nil? then
        params_hash['since'] = since.to_i
      end
      
      r = Typhoeus::Request.new("#{@@fb_host}/checkins", :method => :get, :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      
      # Run this block when the request completes
      r.on_complete do |response|
        puts "START async find checkins for facebook_id_array: #{facebook_id_array} with token: #{@access_token}"
        
        # check for fb errors
        parsed_response = self.check_facebook_response_for_errors(response)
        if parsed_response.nil?
          next
        end
        
        place_id_array = Array.new

        # Parse checkins for each user
        parsed_keys = parsed_response.keys

        # Serialize checkins in bulk
        checkins_array = Array.new
        parsed_keys.each_with_index do |key,i|
          # if there are no recent checkins for this user, don't try to serialize it
          if parsed_response[key]['data'].empty?
            next
          end
          parsed_response[key]['data'].each do |checkin|
            checkins_array << checkin
          end
        end

        if !checkins_array.empty?
          place_id_array = self.serialize_checkin_bulk(checkins_array)
        end

        # Serialize unique list of place_ids
        if !place_id_array.empty?
          self.find_places_for_place_id_array(place_id_array.uniq)
        end

        # Update last_fetched_friends_checkins timestamp for user
        self.update_last_fetched_friends_checkins(facebook_id)

        puts "END async find checkins for facebook_id_array: #{facebook_id_array} with token: #{@access_token}"
      end

      @hydra.queue r # add the request to the queue
    end

    # Finds all checkins for an array of user ids
    # https://graph.facebook.com/checkins?ids=4804606,548430564,645750651&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    # API::FacebookApi.new.find_checkins_for_facebook_id_array()
    def find_checkins_for_facebook_id_array(facebook_id = nil, facebook_id_array = nil, since = nil)
      if facebook_id_array.nil? then
        facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
        #facebook_id_array = ["102167", "107491", "202402", "202451", "206635", "210258", "221423", "222383", "223314", "300994", "404120", "407230", "837181", "1203891", "1204271", "1205313", "1206669", "1207467", "1209924", "1212462", "1214835", "1215870", "1217270", "1217767", "1218796", "1229612", "1237074", "1302698", "2203609", "2414683", "2420700", "2502195", "2502827", "2504814", "2539351", "2602152", "3001631", "3200308", "3200338", "3200785", "3201209", "3207713", "3213585", "3213871", "3213930", "3215015", "3223008", "3224819", "3225115", "3225501", "3302615", "3307216", "3308028", "3312026", "3318595", "3323295", "3400229", "3407534", "3409627", "3414242", "3430753", "3619557", "4804600", "4804606", "4804969", "4805917", "4807345", "4809933", "5505430", "6002685", "6006398", "6010421", "6817010", "7903099", "8620430", "8621075", "8639036", "10703701", "10710317", "10717536", "10718558", "10723087", "10729766", "10731869", "12438683", "12803642", "12805273", "12822783", "13004004", "13704812", "14900845", "67800652", "68600483", "77001082", "500031833", "500676063", "501591312", "503265413", "506408584", "510849527", "543612099", "547177528", "558377300", "573953756", "589860486", "590245157", "591070603", "593399035", "610978642", "624067894", "628447811", "629960217", "645750651", "666112048", "705063052", "707267501", "712743335", "720886950", "745245646", "745938780", "780624163", "802745284", "817333087", "847735037", "883200586", "1008514568", "1017673909", "1059468090", "1067580021", "1099524954", "1121490493", "1155635614", "1184055409", "1224771465", "1316730161", "1321571526", "1483053421", "1653886798", "100000049912171", "100000199684521", "100000576881557", "100000721817834", "100001483789469", "100001893113244"]
        # facebook_id_array = ["8963", "15500", "102167", "107491", "113140", "124718", "200408", "202451", "206635", "221423", "223984", "300994", "304753", "404120", "407230", "602380", "602908", "700411", "700640", "700913", "804962", "806533", "902398", "907578", "926017", "1104245", "1204213", "1205313", "1207135", "1209345", "1215870", "1217270", "1217767", "1232357", "1237074", "1238132", "1302148", "1302698", "1305225", "1317243", "1500280", "1503126", "1602207", "1900323", "1901630", "1946902", "2203649", "2204941", "2205136", "2260313", "2404878", "2420700", "2502195", "2502827", "2504814", "2511909", "2519703", "2520511", "2535681", "2535961", "2539351", "2602139", "2602152", "3001341", "3001631", "3102907", "3207046", "3207713", "3213871", "3214263", "3223008", "3225501", "3309147", "3312630", "3313694", "3318595", "3400229", "3405555", "3407534", "3409627", "3414242", "3422207", "3430753", "3431548", "3500262", "3601361", "3624841", "4200185", "4800419", "4800558", "4801645", "4801649", "4804600", "4804606", "4805917", "4807345", "4809933", "5311725", "5400602", "5401293", "5404625", "5505430", "5722387", "6000997", "6001293", "6002470", "6006398", "6006769", "6006817", "6007206", "6009423", "6010195", "6010421", "6013940", "6020556", "6029659", "6101740", "6103147", "6313486", "6403474", "6817010", "7903099", "7906450", "7944583", "8106362", "8504876", "8620430", "8621075", "8639036", "8819965", "9001569", "9219543", "9300454", "9351864", "10500882", "10701381", "10703701", "10703965", "10705786", "10706085", "10706823", "10707429", "10707911", "10708143", "10708824", "10710317", "10710655", "10712133", "10713943", "10714527", "10717536", "10718558", "10723087", "10723888", "10724566", "10727107", "10729538", "10729766", "10731869", "10732097", "10734785", "11509277", "11710692", "12409925", "12438683", "12801350", "12801778", "12803642", "12804385", "12805273", "12822783", "13004004", "13300908", "13309538", "13601113", "13704812", "13705330", "13710035", "13727874", "13748822", "14900845", "15100199", "15102941", "16103897", "16910989", "19900101", "23709354", "24004576", "27201382", "31900543", "32402049", "32502647", "44404928", "67800652", "68600483", "72606041", "77001082", "217600253", "500031833", "501523903", "503392346", "504450120", "505935283", "506408584", "506672906", "508035217", "510849527", "512078507", "512930451", "515116258", "515772011", "516423668", "517656034", "523260804", "523680072", "529385152", "529767396", "530761351", "531021788", "535022497", "539825468", "543612099", "544881151", "545678688", "546492587", "546542494", "546567064", "546572064", "546631962", "546690648", "547091873", "547098754", "547177528", "547187391", "547272532", "548430564", "549195732", "550827394", "554061179", "554407734", "558377300", "565240108", "565859853", "566189037", "566664300", "569265917", "572521995", "572956856", "573953756", "574953924", "580937949", "589860486", "590245157", "590940415", "591070603", "594160450", "594274171", "594452024", "603927580", "605520271", "606541139", "610604803", "610978642", "618042063", "619680540", "624845905", "628235176", "628976871", "629730750", "629820318", "629960217", "642175690", "643298081", "659752530", "664598837", "666112048", "684786997", "686280655", "688007999", "689596293", "698640330", "699393049", "703427587", "705063052", "707765263", "711951229", "712743335", "713240181", "715882796", "720350220", "720886950", "731347173", "742596203", "743369432", "751377782", "756051583", "761010312", "763045077", "764619434", "768184036", "777725173", "778870130", "780624163", "789287731", "794495829", "794671958", "821640386", "829932247", "843615575", "845320400", "847735037", "883200586", "1006483796", "1007143495", "1008514568", "1020813223", "1031074695", "1037187187", "1041450082", "1041510153", "1055790362", "1056240014", "1059468090", "1083946504", "1153131614", "1157346411", "1171782424", "1224771465", "1276494059", "1294779053", "1316730161", "1364641590", "1393300306", "1397027770", "1433341178", "1452930023", "1491100934", "1524000010", "1543103529", "1553881511", "1556625823", "1636489309", "1640227273", "1653886798", "1682880020", "1682880037", "1682880038", "1746680919", "1772072139", "1846550208", "100000049912171", "100000098807776", "100000160899544", "100000257177602", "100000353950542", "100000452740095", "100000480064561", "100000500324298", "100000631459780", "100000721817834", "100001152622932", "100001158537314", "100001483789469", "100001493170272"];
      end

      if facebook_id.nil? then
        facebook_id = @@peter_id
      end

      puts "START find checkins for facebook_id_array: #{facebook_id_array} with token: #{@access_token}"

      # OLD STYLE BATCHED
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'id,from,tags,place,message,likes,comments,application,created_time'
      params_hash['ids'] = facebook_id_array.join(',')
      params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call
      if !since.nil? then
        params_hash['since'] = since.to_i
      end

      response = Typhoeus::Request.get("#{@@fb_host}/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      
      # puts response.body

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end
      
      place_id_array = Array.new

      # Parse checkins for each user
      parsed_keys = parsed_response.keys

      # Serialize checkins in bulk
      checkins_array = Array.new
      parsed_keys.each_with_index do |key,i|
        # if there are no recent checkins for this user, don't try to serialize it
        if parsed_response[key]['data'].empty?
          next
        end
        parsed_response[key]['data'].each do |checkin|
          checkins_array << checkin
        end
      end
      
      if !checkins_array.empty?
        place_id_array = self.serialize_checkin_bulk(checkins_array)
      end


      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array(place_id_array.uniq)
      end
      
      # Update last_fetched_friends_checkins timestamp for user
      self.update_last_fetched_friends_checkins(facebook_id)

      puts "END find checkins for facebook_id_array: #{facebook_id_array} with token: #{@access_token}"
      
      return true
    end

    ###
    ### Places
    ###

    # https://graph.facebook.com/search?q=pizza&type=place&center=lat,long&distance=1000
    def find_places_near_location(lat = nil, lng = nil, distance = 1000, query = nil)
      # query is optional

      # debug
      if lat.nil? then lat = @@peter_latitude end
      if lng.nil? then lng = @@peter_longitude end

      puts "find places near location lat: #{lat}, lng: #{lng}, distance: #{distance}, query: #{query}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['type'] = 'place'
      params_hash['fields'] = 'id'
      params_hash['center'] = "#{lat},#{lng}"
      params_hash['distance'] = "#{distance.to_i}" # safety force to integer because FBAPI wants int (no decimals)
      params_hash['limit'] = 100 # set this to a really high limit to get all results in one call
      if not query.nil?
        params_hash['q'] = "#{query}"
      end

      response = Typhoeus::Request.get("#{@@fb_host}/search", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return []
      end

      place_id_array = Array.new

      parsed_response['data'].map do |p|
        place_id_array << p["id"]
      end

      puts "place ids: #{place_id_array}"

      # Serialize Places
      # Serialize unique list of place_ids
      if !place_id_array.empty?
        self.find_places_for_place_id_array(place_id_array.uniq)
      end

      # Temporarily return place_id_array for API to query the DB with
      # Later we should perform a new distance based query directly to moogle DB
      return place_id_array
    end

    # https://graph.facebook.com/121328401214612?access_token=2227470867%7C2.i5b1iBZNAy0qqtEfcMTGRg__.3600.1296727200-548430564%7Cxm3tEtVeLY9alHMAh-0Us17qpbg
    # API::FacebookApi.new.find_place_for_place_id(121328401214612)
    # API::FacebookApi.new.find_place_for_place_id(57167660895) # cafe zoe
    def find_place_for_place_id(place_id = nil)
      if place_id.nil? then place_id = 57167660895 end # cafe zoe

      puts "find places for place_id: #{place_id}"

      # fields to get
      # feed - all posts/comments on the page
      # photos - photos posted on the page
      # notes - not sure?
      # checkins - shows checkins from friends of current access_token

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      #params_hash['access_token'] = @access_token
      # params_hash['fields'] = 'feed,photos,notes,checkins'

      # Get Place
      response = Typhoeus::Request.get("#{@@fb_host}/#{place_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end

      # Serialize Place
      self.serialize_place_bulk([parsed_response])

      return true

    end

    # Find all places for an array of place_ids
    # https://graph.facebook.com/?ids=116154718413160,121328401214612,57167660895
    # API::FacebookApi.new.find_places_for_place_id_array([116154718413160,121328401214612,57167660895])
    def find_places_for_place_id_array(place_id_array = nil)
      if place_id_array.nil? then
        place_id_array = [121328401214612,57167660895] # cafe zoe
      end

      puts "find places for place_id_array: #{place_id_array} with token: #{@access_token}"

      place_id_exist_array = Array.new
      puts "Attempt to add #{place_id_array.length} to DB"
      # puts "find places for place_id_array: #{place_id_array}"
      place_id_exist_array = Place.find(:all, :select=>"place_id", :conditions =>"place_id in (#{place_id_array.join(',')})").each do |db_place|
        place_id_array.delete(db_place['place_id'].to_s)
      end
      puts "Actually add #{place_id_array.length} to DB"

      # Only make calls if there are places to pull from Facebook
      if place_id_array.length>0
        puts puts "Inserting #{place_id_array.length} additional places."
        headers_hash = Hash.new
        headers_hash['Accept'] = 'application/json'
        params_hash = Hash.new
        params_hash['access_token'] = @access_token
        params_hash['ids'] = place_id_array.join(',')
        params_hash['limit'] = 2000 # set this to a really high limit to get all results in one call

        response = Typhoeus::Request.get("#{@@fb_host}/", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

        parsed_response = self.check_facebook_response_for_errors(response)
        if parsed_response.nil?
          return false
        end

        # Batch places
        self.serialize_place_bulk(parsed_response)

        puts "find places for place_id_array: #{place_id_array} with token: #{@access_token}"
      
        return true
      else
        return false
      end
    end

    ###
    ### Users/Friends
    ###

    # Finds friends for a single facebook id
    # https://graph.facebook.com/me/friends?fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    # API::FacebookApi.new.find_friends_for_facebook_id()
    def find_friends_for_facebook_id(facebook_id = nil, since = nil)
      if facebook_id.nil? then facebook_id = @@peter_id end

      puts "START find friends for facebook_id: #{facebook_id}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'

      if !since.nil? then
        params_hash['since'] = since.to_i
      end

      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end

      friend_id_array = Array.new

      # Bulk serialize friends
      friend_id_array = self.serialize_friend_bulk(parsed_response['data'],facebook_id,1)

      # Update last_fetched_friends timestamp for user
      self.update_last_fetched_friends(facebook_id)

      puts "END find friends for facebook_id: #{facebook_id}"
      
      return true
    end

    # Finds friends for an array of facebook ids
    # https://graph.facebook.com/friends?ids=4804606,548430564,645750651&fields=third_party_id,first_name,last_name,name,gender,locale&access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    # API::FacebookApi.new.find_friends_for_facebook_id_array
    def find_friends_for_facebook_id_array(facebook_id = nil, facebook_id_array = nil, since = nil)

      if facebook_id.nil? then facebook_id = @@peter_id end

      if facebook_id_array.nil? then
        facebook_id_array = [@@peter_id, @@tom_id, @@james_id]
      end

      puts "START find friends for facebook_id_array: #{facebook_id_array}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'
      params_hash['ids'] = facebook_id_array.join(',')
      if !since.nil? then
        params_hash['since'] = since.to_i
      end

      response = Typhoeus::Request.get("#{@@fb_host}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return false
      end

      # Parse friends for each user
      parsed_keys = parsed_response.keys
      parsed_keys.each do |key|
        # Bulk serialize friends of friends
        self.serialize_friend_bulk([key]['data'],key.to_i,1)
      end

      puts "END find friends for facebook_id_array: #{facebook_id_array}"
      
      return true
    end

    # Find user and serialize by facebook_id; do not use token if you don't have to
    # API::FacebookApi.new.find_user_for_facebook_id(4,1)
    def find_user_for_facebook_id(facebook_id = nil, disable_token=nil)
      if facebook_id.nil? then facebook_id = @@peter_id end
      puts "find user for facebook_id: #{facebook_id}"
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      # By default, use a token and require these specific fields
      params_hash = Hash.new
      if disable_token.nil?
        params_hash['access_token'] = @access_token
        params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'
      else

      end

      response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return nil
      end

      # Parse user
      facebook_user = self.serialize_user(parsed_response)

      return facebook_user
    end

    def find_user_for_facebook_access_token
      puts "find user for access_token: #{@access_token}"

      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale,verified'

      response = Typhoeus::Request.get("#{@@fb_host}/me", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      if parsed_response.nil?
        return nil
      end

      facebook_user = self.serialize_user(parsed_response, @access_token)

      return facebook_user
    end
    
    # Checkin to Facebook
    # Then pull the checkin from Facebook (which also serializes it as a kupos)
    # http://developers.facebook.com/docs/reference/api/checkin/
    # API::FacebookApi.new.add_checkin('hello',152493598101444,37.387650594323, -122.08289289721, '4804606,645750651')
    # adds a checkin without creating kupos
    #
    # Because facebook is stupid and checks lat/lng distance and doesn't allow checkin,
    # We are just gonna hard code the user's lat/lng to that of the place so it never ever fails lol...
    def add_checkin(kupo_id=nil,place_id=nil, message=nil, tags=nil, photo_url=nil, video_url=nil)
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'
      
      # puts "attaching a photo: #{photo_url}"
          
      p = Place.find_by_place_id(place_id)

      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['message'] = message
      params_hash['place'] = place_id
      params_hash['coordinates'] = {"latitude"=>"#{p.lat}","longitude"=>"#{p.lng}"}
      params_hash['tags'] = tags
      
      if !video_url.nil?
        params_hash['name'] ="Kupo!"
        params_hash['picture'] = photo_url
        params_hash['caption'] = "Shared a video via Kupo!"
        params_hash['description'] = message
        params_hash['link'] = "http://kupoapp.com/v1/kupos/#{kupo_id}"
      elsif !photo_url.nil?
        params_hash['name'] = "Kupo!"
        params_hash['picture'] = photo_url
        params_hash['caption'] = "Shared a photo via Kupo!"
        params_hash['description'] = message
        params_hash['link'] = "http://kupoapp.com/v1/kupos/#{kupo_id}"
      end
      
      # params_hash['link'] = photo_url
      # params_hash['picture'] = photo_url
      # params_hash['name'] = "Attached Photo"
      # params_hash['caption'] = "Shared a photo via Moogle"
    
      response = Typhoeus::Request.post("#{@@fb_host}/me/checkins", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      parsed_response = self.check_facebook_response_for_errors(response)
      
      Rails.logger.info "Checked in to facebook with response: #{parsed_response}"
      
      if parsed_response.nil?
        return nil
      else
        # Facebook returns the checkin id
        self.find_checkin_for_checkin_id(parsed_response['id'],false)
      end

      # return Checkin.find_by_checkin_id(parsed_response['id'])
      return parsed_response['id']
      # puts "Should have checked-in to Facebook with returns id #{parsed_response['id']}"
      
    end
    
    # Adding a post to Facebook
    # Message, picture, link, source (video)
    # http://developers.facebook.com/docs/reference/api/post/
    #
    def add_post(kupo_id=nil, message=nil, link=nil, source=nil, tags=nil, photo_url=nil, video_url=nil)
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'
      
      params_hash = Hash.new
      params_hash['access_token'] = @access_token
      params_hash['message'] = message
      params_hash['link'] = link
      params_hash['tags'] = tags
      
      if !source.nil?
        params_hash['name'] ="Kupo!"
        params_hash['picture'] = photo_url
        params_hash['caption'] = "Shared a video via Kupo!"
        params_hash['description'] = message
        params_hash['link'] = "http://kupoapp.com/v1/kupos/#{kupo_id}"
      elsif !photo_url.nil?
        params_hash['name'] = "Kupo!"
        params_hash['picture'] = photo_url
        params_hash['caption'] = "Shared a photo via Kupo!"
        params_hash['description'] = message
        params_hash['link'] = "http://kupoapp.com/v1/kupos/#{kupo_id}"
      else
      end
    
      response = Typhoeus::Request.post("#{@@fb_host}/me/feed", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)
            
      parsed_response = self.check_facebook_response_for_errors(response)
                  
      Rails.logger.info "Checked in to facebook with response: #{parsed_response}"
      
      if parsed_response.nil?
        return nil
      else
        # Facebook returns the checkin id
        self.find_checkin_for_checkin_id(parsed_response['id'],false)
      end

      # return Checkin.find_by_checkin_id(parsed_response['id'])
      return parsed_response['id']
      # puts "Should have checked-in to Facebook with returns id #{parsed_response['id']}"
      
    end
    
    # broken because facebook is retarded
    # Facebook Error Caught: {"type"=>"OAuthException", "message"=>"(#10) Apps must have at least 100 users to use this API"}
    def add_subscriptions
      # https://graph.facebook.com/oauth/access_token?client_id=<app-id>&client_secret=<app-secret>&grant_type=client_credentials
      
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @@fb_app_access_token
      params_hash['object'] = 'user'
      params_hash['fields'] = 'feed'
      # params_hash['callback_url'] = "http://www.kupoapp.com/v1/moogle/fbcallback"
      # params_hash['callback_url'] = "http://99.162.150.93:3000/v1/moogle/fbcallback"
      params_hash['callback_url'] = "http://amigo.no.de/fbcallback"
      params_hash['verify_token'] = 'omgwtfbbq'

      response = Typhoeus::Request.post("#{@@fb_host}/#{@@fb_app_id}/subscriptions", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      puts "raw response: #{response.body}"
      
    end
    
    def get_subscriptions
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @@fb_app_access_token
      
      response = Typhoeus::Request.get("#{@@fb_host}/#{@@fb_app_id}/subscriptions", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      puts "raw response: #{response.body}"
    end
    
    def delete_subscriptions
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'

      params_hash = Hash.new
      params_hash['access_token'] = @@fb_app_access_token
      
      response = Typhoeus::Request.delete("#{@@fb_host}/#{@@fb_app_id}/subscriptions", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

      puts "raw response: #{response.body}"
    end
  end
end
