class Like < ActiveRecord::Base
  belongs_to :snap, :inverse_of => :likes
end
