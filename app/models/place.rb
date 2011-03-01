require 'pp'
require 'yelpscrape'
class Place < ActiveRecord::Base
  has_one :yelp, :foreign_key => 'yelp_pid', :primary_key => 'yelp_pid', :inverse_of => :place
  has_one :gowalla, :foreign_key => 'gowalla_id', :primary_key => 'gowalla_id', :inverse_of => :place
  
  def scrapeYelp
    result = YelpScape.new.yelpResults({'lat'=>self['lat'],'long'=>self['lng'],'query'=>self['name']})
    pp result
    
    y = Yelp.find_or_initialize_by_yelp_pid(result[:url].split('.').last)
    y.yelp_pid = result[:url].split('.').last
    y.name = result[:name]
    y.lat = result[:lat]
    y.lng = result[:lng]
    y.review_count = result[:reviews].size
    y.place_id = self.place_id
    y.save
    
    # result['reviews'].each do |review|
    #     myyelp.reviews.create({
    #         
    #     })
    # end
    
   #  {:name=>"Wedding Photography by IQphoto",
   #   :rating=>"5 star rating",
   #   :url=>"/biz/wedding-photography-by-iqphoto-san-francisco-5",
   #   :hours=>[[540, 1020], [1980, 2460], [3420, 3900], [4860, 5340], [7740, 8220]],
   #   :lat=>37.75367,
   #   :lng=>-122.484731,
   #   :images=>[],
   #   :reviews=>[]
   # }
    
  end
end
