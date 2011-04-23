class Album < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :snaps, :include => :user
  has_one :last_snap, :class_name => 'Snap', :foreign_key => 'id', :primary_key => 'last_snap_id', :include => :user
end
