module API
  class GowallaApi < Api
    
    # User: Moogle
    # Password: rmoogle99
    # curl -H 'X-Gowalla-API-Key: blah' -H 'Accept: application/json' -H 'Content-Type: application/json' -u Moogle:rmoogle99 http://api.gowalla.com/spots?lat=30.2697&lng=-97.7494&radius=50

    def serialize_gowalla(gowalla)

       
    end
    
    
    
    def find_business_by_id(id = nil)

    end
    
    def find_business_by_location(term, latitude, longitude, accuracy, altitude, altitude_accuracy)
      
    end
    
  end
end