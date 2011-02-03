module API
  class Yelp < Api
    # Consumer Key  59qAq_rFiMt26wRMTOXTMA
    # Consumer Secret N5BxbhjpRp5g3iA-SXaDx78jWI0
    # Token ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb
    # Token Secret  vKrHGl5-gGin81a6Mb5ZIwjiHd0
    
    @@api_host = 'api.yelp.com'
    @@consumer_key = '59qAq_rFiMt26wRMTOXTMA'
    @@consumer_secret = 'N5BxbhjpRp5g3iA-SXaDx78jWI0'
    @@token = 'ifKMaMyp7X9JqmCePD3BzskBGYZ1q0Tb'
    @@token_secret = 'vKrHGl5-gGin81a6Mb5ZIwjiHd0'
    
    def self.find_business_by_id(id = nil)
      id = "yelp-san-francisco"
      path = "/v2/business/#{id}"
      
      self.send_oauth_request("http://#{@@api_host}", path, @@consumer_key, @@consumer_secret, @@token, @@token_secret)
    end
    
    def self.find_business_by_location(term, latitude, longitude, accuracy, altitude, altitude_accuracy)
      # http://api.yelp.com/v2/search?term=food&ll=37.788022,-122.399797
      # http://api.yelp.com/v2/search?term=german+food&location=Hayes&cll=37.77493,-122.419415
    end
    
  end
end