class Place < ActiveRecord::Base
  has_one :yelp, :foreign_key => 'yelp_id', :primary_key => 'yelp_id', :inverse_of => :place
  has_one :gowalla, :foreign_key => 'gowalla_id', :primary_key => 'gowalla_id', :inverse_of => :place
end
