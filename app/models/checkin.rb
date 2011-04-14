class Checkin < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :checkins
  belongs_to :kupo, :inverse_of => :checkin
  has_one :place
end
