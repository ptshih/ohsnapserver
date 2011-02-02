class User < ActiveRecord::Base
  has_many :checkins, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :user
end
