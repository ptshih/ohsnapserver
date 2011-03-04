class Share < ActiveRecord::Base
  has_one :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id'
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'
end
