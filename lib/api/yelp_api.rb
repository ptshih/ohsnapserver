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