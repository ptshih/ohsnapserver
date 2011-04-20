class EventController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    # controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # Show all kupos related to an event without using AR
  # http://localhost:3000/v1/events/5/kupos.json?access_token=17fa35a520ac7cc293c083680028b25198feb72033704f1a30bbc4298217065ed310c0d9efae7d05f55c9154601ab767511203e68f02610180ea3990b22ff991&since=1303272472#
  def kupos
    # logging(request, actiontype, lat=nil, lng=nil, var1=nil, var2=nil)
    Rails.logger.info request.query_parameters.inspect
    
    api_call_start = Time.now.to_f
    
    # We should limit results to 50 if no count is specified
     limit_count = "limit 50"
     if !params[:count].nil?
       limit_count = "limit "+params[:count].to_s
     end
     
    # Event filter
    event_condition = "event_id = #{params[:event_id]}"
     
    # Content filter = Video, photo, or video and photo only
    content_type_conditions = ""
    if params[:type].nil?
    elsif params[:type]=="video_only"
      content_type_conditions = " AND has_video=1"
    elsif params[:type]=="photo_only"
      # it's a photo only, not a photo snapshot of video
      content_type_conditions = " AND has_photo=1 AND has_video=0"
    else
      # video OR photo
      content_type_conditions = " AND has_photo+has_video>0"
    end
    
    query = "select k.*, u.facebook_id, u.name
              from kupos k
              join users u on k.user_id = u.id
            where " + event_condition + content_type_conditions + "
            order by k.created_at desc
            " + limit_count
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |k|
      row_hash = {
        :id => k['id'],
        :event_id => k['event_id'],
        :author_id => k['user_id'],
        :author_facebook_id => k['facebook_id'],
        :author_name => k['name'],
        :message => k['message'],
        :has_photo => k['has_photo'],
        :has_video => k['has_video'],
        :photo_file_name => k['photo_file_name'],
        :video_file_name => k['video_file_name'],
        :timestamp => k['updated_at'].to_i
      }
      response_array << row_hash
    end
    
    # Construct Response
    @response_hash = {}
    @response_hash[:data] = response_array
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,nil,'event#kupos',nil,nil,api_call_duration,params[:event_id],nil,nil)
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @response_hash }
      format.json  { render :json => @response_hash }
    end
  end
  
  # Show all kupos related to an event
  def kupos_ar
    # logging(request, actiontype, lat=nil, lng=nil, var1=nil, var2=nil)
    Rails.logger.info request.query_parameters.inspect
    
    api_call_start = Time.now.to_f
    
    # We should limit results to 50 if no count is specified
     limit_count = 50
     if !params[:count].nil?
       limit_count = params[:count].to_i
     end
     
    # Video, photo, or video and photo only
    set_conditions = "event_id = #{params[:event_id]}"
    if params[:type].nil?
    elsif params[:type]=="video_only"
      set_conditions = "event_id = #{params[:event_id]} AND has_video=1"
    elsif params[:type]=="photo_only"
      # it's a photo only, not a photo snapshot of video
      set_conditions = "event_id = #{params[:event_id]} AND has_photo=1 AND has_video=0"
    else
      # video OR photo
      set_conditions = "event_id = #{params[:event_id]} AND has_photo+has_video>0"
    end

    kupos = Kupo.find(:all, :conditions => set_conditions, :order => 'created_at DESC', :limit => limit_count)
    
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
    LOGGING::Logging.logfunction(request,nil,'event#kupos',nil,nil,api_call_duration,params[:event_id],nil,nil)
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @response_hash }
      format.json  { render :json => @response_hash }
    end
  end
  
  # Create a new event along with the first kupo associated to it
  def new
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    e = Event.create(
      :tag => params[:tag],
      :name => params[:name]
    )
    
    k = Kupo.create(
      :source => params[:source],
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
    
    e.kupos << k
    
    e.update_attribute(:last_kupo_id, k.id)
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'event#new',nil,nil,api_call_duration,k.id,k.event_id,k.user_id)
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end
