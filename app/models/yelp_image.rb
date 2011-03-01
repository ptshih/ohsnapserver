class YelpImage < ActiveRecord::Base
  belongs_to :yelp, :foreign_key => 'yelp_pid', :primary_key => 'yelp_pid', :inverse_of => :yelp_reviews
end
