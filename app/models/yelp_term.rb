class YelpTerm < ActiveRecord::Base
  has_and_belongs_to_many :yelps
end