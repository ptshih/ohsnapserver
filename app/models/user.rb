class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  
  has_many :snaps, :inverse_of => :user
  has_and_belongs_to_many :albums
end
