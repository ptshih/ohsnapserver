class Friendship < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id'
  belongs_to :friend, :class_name => 'User', :foreign_key => 'friend_id', :primary_key => 'facebook_id'
end
