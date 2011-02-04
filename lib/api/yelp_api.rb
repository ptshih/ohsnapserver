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
       y = Yelp.find_or_initialize_by_place_id(yelp['id'])
       y.place_id = yelp['id']
       y.name = yelp['name']
       y.phone = yelp['phone']
       y.review_count = yelp['review_count']
       y.lat = yelp['coordinate']['latitude']
       y.lng = yelp['coordinate']['longitude']
       y.raw_hash = yelp
       y.expires_at = Time.now + 1.days
       y.save
       
       r = YelpReview.find_or_initialize_by_yelp_review_id(yelp['reviews']['id'])
       r.yelp_id = yelp['id']
       r.excerpt = yelp['reviews']['excerpt']
       r.rating = yelp['reviews']['rating']
       r.time_created = Time.parse(yelp['review']['time_created'])
       r.user_name = yelp['reviews']['user']['name']
       r.user_id = yelp['reviews']['user']['id']
       r.raw_hash = yelp['reviews']
       r.save
       
    end
    
    
    
    def self.find_business_by_id(id = nil)
      id = "yelp-san-francisco"
      path = "/v2/business/#{id}"
      
      response = self.send_oauth_request("http://#{@@apiHost}", path, @@consumerKey, @@consumerSecret, @@token, @@tokenSecret)
      
      parsedResponse = self.parse_json(response)
    end
    
    def self.find_business_by_location(term, latitude, longitude, accuracy, altitude, altitudeAccuracy)
      # http://api.yelp.com/v2/search?term=food&ll=37.788022,-122.399797
      # http://api.yelp.com/v2/search?term=german+food&location=Hayes&cll=37.77493,-122.419415
    end
    
  end
end