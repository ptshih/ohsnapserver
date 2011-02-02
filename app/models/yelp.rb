class Yelp < ActiveRecord::Base
  belongs_to :place, :foreign_key => 'place_id', :primary_key => 'place_id', :inverse_of => :yelp
end
