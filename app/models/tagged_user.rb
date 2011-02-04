class TaggedUser < ActiveRecord::Base
  has_one :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id'
end
