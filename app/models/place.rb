require 'pp'
# require 'yelpscale'
class Place < ActiveRecord::Base
  has_one :yelp, :foreign_key => 'yelp_id', :primary_key => 'yelp_id', :inverse_of => :place
  has_one :gowalla, :foreign_key => 'gowalla_id', :primary_key => 'gowalla_id', :inverse_of => :place
  
  def scrapeYelp
    result = YelpScape.new.yelpResults({'lat'=>self['lat'],'long'=>self['lng'],'query'=>self['name']})
    pp result
    myyelp = self.create_yelp({
        :name => result['name'],
        :lat =>result['lat'],
        :lng => result['long'],
        :review_count => result['reviews'].size
    }).save
    
    # result['reviews'].each do |review|
    #     myyelp.reviews.create({
    #         
    #     })
    # end
  end
end
