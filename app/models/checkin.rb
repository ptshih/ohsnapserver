class Checkin < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :checkins
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'
  has_one :app, :foreign_key => 'app_id', :primary_key => 'app_id'
  has_many :tagged_users, :foreign_key => 'checkin_id', :primary_key => 'checkin_id', :inverse_of => :checkin
  has_many :checkin_likes, :foreign_key => 'checkin_id', :primary_key => 'checkin_id', :inverse_of => :checkin
  has_many :checkin_comments, :foreign_key => 'checkin_id', :primary_key => 'checkin_id', :inverse_of => :checkin  
end
