module API
  class Facebook < Api
    @@fbHost = 'https://graph.facebook.com'
    @@peterId = 548430564
    # Peter's access token
    @@peterAccessToken = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
    # https://graph.facebook.com/548430564/checkins?access_token=H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA
    
    def self.find_checkins_for_facebook_id(facebookId = @@peterId)
      shouldAcceptCompressedResponse = false
      headersHash = Hash.new
      headersHash['Accept'] = "application/json"
      if shouldAcceptCompressedResponse then
        headersHash['Accept-Encoding'] = "gzip"
      end
      
      
      response = Typhoeus::Request.get("#{@@fbHost}/#{facebookId}/checkins", :params => {:access_token => @@peterAccessToken}, :headers => headersHash, :disable_ssl_peer_verification => true)      
      p response.body
    end
  end
end