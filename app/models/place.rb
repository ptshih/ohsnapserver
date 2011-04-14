# require 'pp'
# require 'yelp_scraper'
class Place < ActiveRecord::Base
  belongs_to :kupo, :inverse_of => :place
  
  def scrape_yelp
    result = YelpScraper.new.yelpResults({'lat'=>self['lat'],'long'=>self['lng'],'query'=>self['name']})
    pp result
    
    if !result.nil?
      serialize_yelp(result)
      self.reload
    else
      puts "Failed to correlate with Yelp"
      
      # We should set an invalid flag on the place so we don't try and re-scrape yelp again
      self.update_attribute('yelp_pid', 'omgwtfbbq')  
    end

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
  
  def serialize_yelp(result)
    yelp_pid = result[:url].split('/').last
    y = Yelp.find_or_initialize_by_yelp_pid(yelp_pid)
    y.place_id = self.place_id
    y.yelp_pid = yelp_pid
    y.name = result[:name]
    y.rating = result[:rating]
    y.lat = result[:lat]
    y.lng = result[:lng]
    y.review_count = result[:reviews].size
    
    if !result[:categories].empty?
      result[:categories].each do |category|
        y.yelp_categories << YelpCategory.find_or_initialize_by_category(:category => category)
      end
    end
    
      
    terms = YelpScraper.new.extractTermsForYelpBiz("#{result[:url]}")
    pp terms
    
    if !terms["Result"].empty?
      terms["Result"].each do |term|
        y.yelp_terms << YelpTerm.find_or_initialize_by_term(:term => term)
      end
    end
    
    y.save
    
    serialize_yelp_images(yelp_pid ,result[:images])
    serialize_yelp_reviews(yelp_pid, result[:reviews])
    
    self.update_attribute('yelp_pid', yelp_pid)
  end
  
  def serialize_yelp_reviews(yelp_pid, reviews)
    old_reviews = YelpReview.find_all_by_yelp_pid(yelp_pid)
    if not old_reviews.nil?
      old_reviews.each do |old_review|
        old_review.delete
      end
    end
    
    reviews.each do |review|
      r = YelpReview.create(
        :yelp_pid => yelp_pid,
        :rating => review[:rating],
        :text => review[:text]
      )
    end
  end
  
  def serialize_yelp_images(yelp_pid, images)
    images.each do |image_url|
      i = YelpImage.find_or_initialize_by_url(image_url)
      i.yelp_pid = yelp_pid
      i.url = image_url
      i.save
    end
  end
end
