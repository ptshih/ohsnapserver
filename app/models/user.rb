class User < ActiveRecord::Base
  has_many :checkins, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :user
  has_many :friendships
  has_many :friends, :through => :friendships
  
  has_many :kupos, :inverse_of => :user
  has_and_belongs_to_many :events
end
