class Event < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :kupos
  has_one :last_kupo, :class_name => 'Kupo', :foreign_key => 'id', :primary_key => 'last_kupo_id'
end
