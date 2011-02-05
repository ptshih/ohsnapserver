module API
  class YelpApi < Api
    # Consumer Key  59qAq_rFiMt26wRMTOXTMA
    # Consumer Secret N5BxbhjpRp5g3iA-SXaDx78jWI0
    # Token ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb
    # Token Secret  vKrHGl5-gGin81a6Mb5ZIwjiHd0
    
    @@apiHost = 'api.yelp.com'
    @@consumerKey = '59qAq_rFiMt26wRMTOXTMA'
    @@consumerSecret = 'N5BxbhjpRp5g3iA-SXaDx78jWI0'
    @@token = 'ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb'
    @@tokenSecret = 'vKrHGl5-gGin81a6Mb5ZIwjiHd0'
    
    
    # Create or update yelp in model/database
    def self.serialize_yelp(yelp)

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
       y.raw_hash = yelp
       y.expires_at = Time.now + 1.days
       y.save
       
       yelp['reviews'].each do |review|
         r = YelpReview.find_or_initialize_by_yelp_review_pid(review['id'])
          r.yelp_review_pid = review['id']
          r.yelp_id = y.id
          r.excerpt = review['excerpt'].nil? ? nil : review['excerpt']
          r.rating = review['rating'].nil? ? nil : review['rating']
          r.time_created = Time.at(review['time_created'])
          r.user_name = review['user']['name'].nil? ? nil : review['user']['name']
          r.user_id = review['user']['id'].nil? ? nil : review['user']['id']
          r.raw_hash = review
          r.save
       end

       
    end
    
    
    
    def self.find_business_by_id(id = nil)
      #id = "yelp-san-francisco"
      path = "/v2/business/#{id}"
      
      response = self.send_oauth_request("http://#{@@apiHost}", path, @@consumerKey, @@consumerSecret, @@token, @@tokenSecret)
      parsedResponse = self.parse_json(response)
      
      self.serialize_yelp(parsedResponse)
      
    end
    
    def self.find_business_by_location(term, latitude, longitude, accuracy, altitude, altitudeAccuracy)
      # http://api.yelp.com/v2/search?term=food&ll=37.788022,-122.399797
      # http://api.yelp.com/v2/search?term=german+food&location=Hayes&cll=37.77493,-122.419415
    end
    
  end
end