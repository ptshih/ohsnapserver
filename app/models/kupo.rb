class Kupo < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :kupos
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'
  has_one :checkin, :foreign_key => 'checkin_id', :primary_key => 'checkin_id'
end
