class EventController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  def kupos
    # logging(request, actiontype, lat=nil, lng=nil, var1=nil, var2=nil)
    Rails.logger.info request.query_parameters.inspect
    
    api_call_start = Time.now.to_f
    
    # We should limit results to 50 if no count is specified
     limit_count = 50
     if !params[:count].nil?
       limit_count = params[:count].to_i
     end
    
    kupos = Kupo.find(:all, :conditions => "event_id = #{params[:event_id]}", :order => 'created_at DESC', :limit => limit_count)
    
    response_array = []
    kupos.each do |k|
      row_hash = {
        :id => k.id.to_s,
        :event_id => k.event_id.to_s,
        :author_id => k.user.id.to_s,
        :author_facebook_id => k.user.facebook_id.to_s,
        :author_name => k.user.name,
        :message => k.message,
        :has_photo => k.has_photo,
        :has_video => k.has_video,
        :photo_file_name => k.photo_file_name,
        :video_file_name => k.video_file_name,
        :timestamp => k.updated_at.to_i
      }
      response_array << row_hash
    end
    
    # Construct Response
    @response_hash = {}
    @response_hash[:data] = response_array
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'kupos',nil,nil,api_call_duration,params[:event_id],nil,nil)
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @response_hash }
      format.json  { render :json => @response_hash }
    end
  end
  
  def new
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    api_call_start = Time.now.to_f
    k = Kupo.create(
      :facebook_id => @current_user.facebook_id,
      :kupo_type => params[:kupo_type].to_i,
      :place_id => params[:place_id],
      :comment => params[:comment],
      :photo => params[:image],
      :has_photo => params[:image].nil? ? false : true,
      :has_video => params[:video].nil? ? false : true,
      :video => params[:video],
      :created_at => Time.now
    )
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'addkupos',nil,nil,api_call_duration,k.id,k.kupo_type,k.place_id)
    response = {:success => "true"}
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
  end
  
end
