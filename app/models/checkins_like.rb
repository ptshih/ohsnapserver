class CheckinsLike < ActiveRecord::Base
  has_one :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id'
  belongs_to :checkin, :foreign_key => 'checkin_id', :primary_key => 'checkin_id', :inverse_of => :checkins_like
end
