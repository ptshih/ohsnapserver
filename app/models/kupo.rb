class Kupo < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :kupos
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'

  has_attached_file :photo,
    :storage => :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
    :path => "/:class/:attachment/:id/:style/:filename",
    :url => "/:class/:attachment/:id/:style_:basename.:extension",
    :default_url => "/:class/:attachment/missing_:style.png",
    :whiny_thumbnails => true,
    :styles => { :square => "50x50#", :full => "280x280>"
    }
    # has_attached_file :photo, 
    #   :storage => :s3, 
    #   :s3_credentials => "#{RAILS_ROOT}/config/s3.yml", 
    #   :path => "/:style/:filename"
end
