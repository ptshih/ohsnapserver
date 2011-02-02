class Checkin < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :checkins
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'
  has_one :app, :foreign_key => 'app_id', :primary_key => 'app_id'
end
