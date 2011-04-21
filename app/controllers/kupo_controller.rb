class KupoController < ApplicationController
  before_filter :default_geocoordinates
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    # controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  ###
  ### Convenience Methods
  ###
  
  ###
  ### API Endpoints
  ###
  
  def index
  end
  
  # http://localhost:3000/v1/kupo/16/kupos.json?access_token=17fa35a520ac7cc293c083680028b25198feb72033704f1a30bbc4298217065ed310c0d9efae7d05f55c9154601ab767511203e68f02610180ea3990b22ff991
  def show
    k = Kupo.find_by_id(params[:kupo_id])
    
    @media_type = nil
    @media_url = nil
    if k.has_video?
      @media_type = "video"
      @media_url = "http://s3.amazonaws.com/scrapboard/kupos/videos/#{k.id}/original/#{k.video_file_name}"
    elsif k.has_photo?
      @media_type = "photo"
      @media_url = "http://s3.amazonaws.com/scrapboard/kupos/photos/#{k.id}/original/#{k.photo_file_name}"
    else
      @media_url = "#{k.message}"
    end
    
    respond_to do |format|
      format.html # template
    end
  end
  
  def search
  end
  
  def new
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    k = Kupo.create(
      :source => params[:source],
      :event_id => params[:event_id],
      :user_id => @current_user.id,
      :facebook_place_id => params[:facebook_place_id],
      :facebook_checkin_id => params[:facebook_checkin_id],
      :message => params[:message],
      :photo => params[:image],
      :video => params[:video],
      :has_photo => params[:image].nil? ? false : true,
      :has_video => params[:video].nil? ? false : true,
      :lat => params[:lat].nil? ? params[:lat] : nil,
      :lng => params[:lng].nil? ? params[:lng] : nil
    )
    
    k.event.update_attribute(:last_kupo_id, k.id)
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'kupo#new',nil,nil,api_call_duration,k.id,k.event_id,k.user_id)
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end
