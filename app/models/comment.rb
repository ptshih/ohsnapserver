class Comment < ActiveRecord::Base
  belongs_to :snap, :inverse_of => :comments
end
