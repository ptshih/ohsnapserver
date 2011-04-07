class Kupo < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'facebook_id', :primary_key => 'facebook_id', :inverse_of => :kupos
  has_one :place, :foreign_key => 'place_id', :primary_key => 'place_id'
  before_create :randomize_file_name

  has_attached_file :photo,
    :storage => :s3,
    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
    :path => "/:class/:attachment/:id/:style/:filename",
    :url => "/:class/:attachment/:id/:style_:basename.:extension",
    :default_url => "/:class/:attachment/missing_:style.png",
    :whiny_thumbnails => true,
    :styles => { :thumb => "100x100#" , :square => "50x50#" }
    # has_attached_file :photo, 
    #   :storage => :s3, 
    #   :s3_credentials => "#{RAILS_ROOT}/config/s3.yml", 
    #   :path => "/:style/:filename"
  has_attached_file :video,
    :storage => :s3,
    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
    :path => "/:class/:attachment/:id/:style/:filename",
    :url => "/:class/:attachment/:id/:style_:basename.:extension"
    
  private
  def randomize_file_name
    if !photo_file_name.nil?
      photo_extension = File.extname(photo_file_name).downcase
      self.photo.instance_write(:file_name, "#{ActiveSupport::SecureRandom.hex(16)}#{photo_extension}")
    end
    if !video_file_name.nil?
      video_extension = File.extname(video_file_name).downcase
      self.video.instance_write(:file_name, "#{ActiveSupport::SecureRandom.hex(16)}#{video_extension}")
    end
  end
end
