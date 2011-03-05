class Yelp < ActiveRecord::Base
  has_many :yelp_reviews, :foreign_key => 'yelp_pid', :primary_key => 'yelp_pid', :inverse_of => :yelp
  has_many :yelp_images, :foreign_key => 'yelp_pid', :primary_key => 'yelp_pid', :inverse_of => :yelp
  belongs_to :place, :foreign_key => 'place_id', :primary_key => 'place_id', :inverse_of => :yelp
  has_and_belongs_to_many :yelp_categories
  has_and_belongs_to_many :yelp_terms
end
