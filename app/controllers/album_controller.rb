class AlbumController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    # controller.authenticate_token # sets the @current_user var based on passed in access_token
  end

  # Show a list of albums for the authenticated user (or optionally any user if public)
  # @param REQUIRED access_token
  # @param OPTIONAL user_id
  # Authentication required
  def index
    self.authenticate_token

    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f

    ########
    # NOTE #
    ########
    # All response_hash objects should follow this format...
    # object_hash is a hash with a key called :data
    # object_hash[:data] has an array of hashes that represent a single object (response_array contains many row_hash)
    # object_hash[:paging] is optional and has a key :since and key :until
    # :since is the :timestamp of the first object in response_array
    # :until is the :timestamp of the last object in response_array
    #
    # A subhash inside row_hash (i.e. participants_hash) will have the same format, just no :paging

    ###
    # Getting participants
    ###
    participants_hash = {}

    # Prepare Query
    query = "
      select au.album_id, u.id, u.name, u.first_name, u.picture_url
      from albums_users au
      join users u on au.user_id = u.id
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      if !participants_hash.has_key?(row['album_id'].to_s)
        participants_hash[row['album_id'].to_s] = []
      end
      participant_hash = {
        :id => row['id'],
        :name => row['name'],
        :first_name => row['first_name'],
        :picture_url => row['picture_url']
      }
      participants_hash[row['album_id'].to_s] << participant_hash
    end

    ###
    # Getting albums
    ###

    # Prepare Query
    query = "
      select
        a.id, a.name, s.user_id, u.name as 'user_name', u.picture_url,
        s.message, s.type, s.lat, s.lng, a.updated_at
      from albums a
      join snaps s on a.last_snap_id = s.id
      join users u on u.id = s.user_id
    "
    
    # Fetch Results
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      # Each response hash consists of album id, name, and last_snap details flattened
      row_hash = {
        :id => row['id'], # album id
        :name => row['name'], # album name
        :user_id => row['user_id'], # last_snap user id
        :user_name => row['user_name'], # last_snap user name
        :user_picture_url => row['user_picture_url'], #last_snap user picture url (facebook or google)
        :message => row['message'], # last_snap message
        :last_activity => last_activity,
        :type => row['type'], # last_snap type
        :lat => row['lat'],
        :lng => row['lng'],
        :participants => participants_hash[row['album_id'].to_s], # list of participants for this album
        :timestamp => row['updated_at'].to_i # album updated_at
      }
      response_array << row_hash
    end

    # Paging
    paging_hash = {}
    paging_hash[:since] = response_array.first[:timestamp]
    paging_hash[:until] = response_array.last[:timestamp]

    # Construct Response
    @response_hash = {}
    @response_hash[:data] = response_array
    @response_hash[:paging] = paging_hash

    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'album#index',nil,nil,api_call_duration,nil,nil,nil)

    respond_to do |format|
      format.html # event/kupos.html.erb template
      format.xml  { render :xml => @response_hash }
      format.json  { render :json => @response_hash }
    end
  end

  # Create a new album along with the first snap associated to it
  # @param REQUIRED access_token
  # Authentication required
  def create
    self.authenticate_token

    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f

    # Should we create the event tag on the server side? (probably)
    # tag = "#" + params[:name].gsub(/[^0-9A-Za-z]/, '')
    # tag.downcase!
    # tag_count = Event.count(:conditions => "tag LIKE '%#{tag}.%'")
    # tag = tag + ".#{tag_count + 1}"

    # 1. Create a new Album
    # 2. Fill Album with POST data
    # 3. Create a new Snap
    # 4. Fill Snap with POST data, set :album_id to newly created Album
    # 5. Set Album last_snap_id to newly created Snap
    # 6. Set albums_users join table entry for newly created Album

    # e = Event.create(
    #   :tag => tag,
    #   :name => params[:name]
    # )
    #
    # k = Kupo.create(
    #   :source => params[:source],
    #   :user_id => @current_user.id,
    #   :facebook_place_id => params[:facebook_place_id],
    #   :facebook_checkin_id => params[:facebook_checkin_id],
    #   :message => params[:message],
    #   :photo => params[:image],
    #   :video => params[:video],
    #   :has_photo => params[:image].nil? ? false : true,
    #   :has_video => params[:video].nil? ? false : true,
    #   :lat => params[:lat].nil? ? params[:lat] : nil,
    #   :lng => params[:lng].nil? ? params[:lng] : nil
    # )
    #
    # e.kupos << k
    #
    # e.update_attribute(:last_kupo_id, k.id)
    #
    # @current_user.events << e

    response = {:success => "true"}

    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'album#create',nil,nil,api_call_duration,nil,nil,nil)

    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end

  end


  ###
  ### OLD APIs, for more see the scrapboard repo
  ###

  # Show all kupos related to an event without using AR
  # http://localhost:3000/v1/kupos/16?access_token=17fa35a520ac7cc293c083680028b25198feb72033704f1a30bbc4298217065ed310c0d9efae7d05f55c9154601ab767511203e68f02610180ea3990b22ff991
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
        :id => k['id'].to_s,
        :event_id => k['event_id'].to_s,
        :author_id => k['user_id'].to_s,
        :author_facebook_id => k['facebook_id'].to_s,
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
      format.html # event/kupos.html.erb template
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

  def test
    test_response = %{
      {
        "data" : [
          {
            "id" : "1",
            "name" : "Poker Night 3",
            "user_id" : "1",
            "user_name" : "Peter Shih",
            "user_picture_url" : "http://localhost:3000/tmp.png",
            "message" : "Lost $20 in one hand...",
            "type" : "photo",
            "lat" : "37.7805",
            "lng" : "-122.4100",
            "timestamp" : 1300930808
          },
          {
            "id" : "2",
            "name" : "Girls Girls Girls!",
            "user_id" : "2",
            "user_name" : "James Liu",
            "user_picture_url" : "http://localhost:3000/tmp.png",
            "message" : "Look at them booty!",
            "type" : "photo",
            "lat" : "37.7815",
            "lng" : "-122.4101",
            "timestamp" : 1290150808
          },
          {
            "id" : "3",
            "name" : "Nice Cars, etc...",
            "user_id" : "3",
            "user_name" : "Nathan Bohannon",
            "user_picture_url" : "http://localhost:3000/tmp.png",
            "message" : "R8 in front of verde",
            "type" : "photo",
            "lat" : "37.7825",
            "lng" : "-122.4102",
            "timestamp" : 1290140802
          },
          {
            "id" : "4",
            "name" : "Verde Tea",
            "user_id" : "3",
            "user_name" : "Thomas Liou",
            "user_picture_url" : "http://localhost:3000/tmp.png",
            "message" : "Hotties!",
            "type" : "photo",
            "lat" : "37.7825",
            "lng" : "-122.4102",
            "timestamp" : 1290130802
          }
        ],
        "paging" : {
          "since" : 1300930808,
          "until" : 1290130802
        }
      }
    }

    render :json => test_response
    return
  end
end
