module API
  class YelpApi < Api
    # Consumer Key  59qAq_rFiMt26wRMTOXTMA
    # Consumer Secret N5BxbhjpRp5g3iA-SXaDx78jWI0
    # Token ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb
    # Token Secret  vKrHGl5-gGin81a6Mb5ZIwjiHd0
    
    @@api_host = 'api.yelp.com'
    @@consumer_key = '59qAq_rFiMt26wRMTOXTMA'
    @@consumer_secret = 'N5BxbhjpRp5g3iA-SXaDx78jWI0'
    @@token = 'ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb'
    @@token_secret = 'vKrHGl5-gGin81a6Mb5ZIwjiHd0'
    
    
    # Create or update yelp in model/database
    def serialize_yelp(yelp)

       y = Yelp.find_or_initialize_by_yelp_pid(yelp['id'])
       y.yelp_pid = yelp['id']
       y.name = yelp['name'].nil? ? nil : yelp['name']
       y.phone = yelp['phone'].nil? ? nil : yelp['phone']
       y.review_count = yelp['review_count'].nil? ? nil : yelp['review_count']
       y.street = yelp['location']['address'].nil? ? nil : yelp['location']['address']
       y.city = yelp['location']['city'].nil? ? nil : yelp['location']['city']
       y.state = yelp['location']['state_code'].nil? ? nil : yelp['location']['state_code']
       y.country = yelp['location']['country_code'].nil? ? nil : yelp['location']['country_code']
       y.zip = yelp['location']['postal_code'].nil? ? nil : yelp['location']['postal_code']
       y.lat = yelp['location']['coordinate']['latitude'].nil? ? nil : yelp['location']['coordinate']['latitude']
       y.lng = yelp['location']['coordinate']['longitude'].nil? ? nil : yelp['location']['coordinate']['longitude']
       y.expires_at = Time.now + 1.days
       y.save
       
       if !yelp['review'].nil?
       
         yelp['reviews'].each do |review|
           r = YelpReview.find_or_initialize_by_yelp_review_pid(review['id'])
            r.yelp_review_pid = review['id']
            r.yelp_id = y.id
            r.excerpt = review['excerpt'].nil? ? nil : review['excerpt']
            r.rating = review['rating'].nil? ? nil : review['rating']
            r.time_created = Time.at(review['time_created'])
            r.user_name = review['user']['name'].nil? ? nil : review['user']['name']
            r.user_id = review['user']['id'].nil? ? nil : review['user']['id']
            r.save
         end

       end
       
       return y

    end
    
    
    
    def find_business_by_id(id = nil)
      # API::YelpApi.new.find_business_by_id("cafe-zoe-menlo-park")
      #id = "yelp-san-francisco"
      path = "/v2/business/#{id}"
      
      response = self.send_oauth_request("http://#{@@api_host}", path, @@consumer_key, @@consumer_secret, @@token, @@token_secret)
      parsed_response = self.parse_json(response)
      
      self.serialize_yelp(parsed_response)
      
    end
    
    def find_business_by_location(term, latitude, longitude, accuracy=nil, altitude=nil, altitude_accuracy=nil)
      
      # API::YelpApi.find_business_by_location("CAFE Zoe", 37.459097,-122.152712)
      # http://api.yelp.com/v2/search?term=food&ll=37.788022,-122.399797
      # http://api.yelp.com/v2/search?term=german+food&location=Hayes&cll=37.77493,-122.419415

      #cgi_term = CGI::escapeHTML(term)
      #encoded_term = URI::encode(cgi_term)

      cgi_term = CGI::escape(term)
      path = "/v2/search?term=#{cgi_term}&ll=#{latitude},#{longitude}&limit=10"
      
      puts "Yelp path: #{path}"
      
      response = self.send_oauth_request("http://#{@@api_host}", path, @@consumer_key, @@consumer_secret, @@token, @@token_secret)
      parsed_response = self.parse_json(response)
      
      puts "#{parsed_response}"
      
      # Keep the first result as best business match for parameters passed
      yelp_object=nil
      
      parsed_response['businesses'].each do |business|
        yelp = self.serialize_yelp(business)
        if yelp_object.nil?
          yelp_object = yelp
        end
      end
      
      # return yelp_id to save
      return yelp_object
            
    end
    
    # Pass in place id (this is the table place column id value)
    def correlate_yelp_to_place_with_place_id(place_id = nil)
    
      p = Place.find_by_id(place_id)
      
      # Only correlate if place object exists in database
      if !p.nil?
        yelp = self.find_business_by_location(p.name, p.lat, p.lng)
        # Save yelp_id if found correlate Yelp place, else store -1
        if yelp.nil?
          p.yelp_id=-1
        else
          p.yelp_id = yelp.id
          puts "Correlated place #{p.id} #{p.name} with yelp #{yelp.yelp_pid} #{yelp.name}"
        end
        p.save
      end
      
    end
    
    # Pass in place_id array (this is the place_id as used by facebook)
    # API::YelpApi.new.correlate_yelp_to_place_with_place_place_id_array([57167660895])
    # API::YelpApi.new.correlate_yelp_to_place_with_place_place_id_array([152792071397735])
    # API::YelpApi.new.correlate_yelp_to_place_with_place_place_id_array([111725255530550])
    def correlate_yelp_to_place_with_place_place_id_array(place_id_array = nil)
      
      # Only look for yelp correlation if there are places
      if !place_id_array.nil?
        place_id_array.each do |place_id|
          p = Place.find_by_place_id(place_id)
          
          # Only correlate places which aren't already correlated
          if p.yelp_id.zero?
            self.correlate_yelp_to_place_with_place_id(p.id)
          end
        end
      end
      
    end
    
  end
end