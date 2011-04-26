class SnapController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    # controller.authenticate_token # sets the @current_user var based on passed in access_token
  end
  
  # Show a list of snaps for an album
  # @param REQUIRED album_id
  # Authentication not required
  def index
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
    
    comments_hash_array ={}
    likes_hash_array = {}
    
    # Prepare Comment Query
    query = "
      select c.snap_id, c.user_id, u.name as 'user_name', c.message
      from snap_comments c
      join users u on c.user_id = u.id
      where c.album_id = #{params[:album_id]}
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      if !comments_hash_array.has_key?(row['snap_id'].to_s)
        comments_hash_array[row['snap_id'].to_s] = []
      end
      sub_hash = {
        :snap_id => row['snap_id'],
        :user_id => row['user_id'],
        :user_name => row['user_name'],
        :message => row['message']
      }
      comments_hash_array[row['snap_id'].to_s] << sub_hash
    end
    
    # Prepare Likes Query
    query = "
      select l.snap_id, l.user_id, u.name as 'user_name'
      from snap_likes l
      join users u on l.user_id = u.id
      where album_id = #{params[:album_id]}
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      if !likes_hash_array.has_key?(row['snap_id'].to_s)
        likes_hash_array[row['snap_id'].to_s] = []
      end
      sub_hash = {
        :snap_id => row['snap_id'],
        :user_id => row['user_id'],
        :user_name => row['user_name']
      }
      likes_hash_array[row['snap_id'].to_s] << sub_hash
    end
    
    # Prepare Snap Query
    query = "
      select
        s.id,
        s.album_id,
        s.user_id,
        u.name as 'user_name',
        u.picture_url as 'user_picture_url',
        s.message,
        s.type,
        s.photo_file_name,
        s.video_file_name,
        s.lat,
        s.lng,
        s.updated_at
      from snaps s
      join users u on s.user_id = u.id
      where s.album_id = #{params[:album_id]}
    "
    
    # Fetch Results
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      # Each response hash consists of album id, name, and last_snap details flattened
      row_hash = {
        :id => row['id'], # snap id
        :album_id => row['album_id'], # album id
        :user_id => row['user_id'], # snap user id
        :user_name => row['user_name'], # last_snap user name
        :user_picture_url => row['user_picture_url'], #last_snap user picture url (facebook or google)
        :message => row['message'], # last_snap message
        :type => row['type'], # last_snap type
        :photo_file_name => row['photo_file_name'], # photo file name or nil
        :video_file_name => row['video_file_name'], # video file name or nil
        :lat => row['lat'],
        :lng => row['lng'],
        :is_liked => likes_hash_array.has_key?(row['id'].to_s),
        :comments => comments_hash_array[row['id'].to_s],
        :likes => likes_hash_array[row['id'].to_s],
        :timestamp => row['updated_at'].to_i # snap updated_at
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
    LOGGING::Logging.logfunction(request,@current_user.id,'snap#index',nil,nil,api_call_duration,nil,nil,nil)
    
    respond_to do |format|
      format.html # event/kupos.html.erb template
      format.xml  { render :xml => @response_hash }
      format.json  { render :json => @response_hash }
    end
  end
  
  # Create a new snap
  # @param REQUIRED album_id
  # @param REQUIRED access_token
  # Authentication required
  def create
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    # 1. Create a new Snap for request param album_id
    # 2. Fill Snap with POST data, set :album_id to request param album_id
    # 5. Set Album (from request param) last_snap_id to newly created Snap
    # 6. Set albums_users join table entry for Album
    

    response = {:success => "true"}
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'snap#create',nil,nil,api_call_duration,nil,nil,nil)
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
  end
  
  # Delete a snap
  # @param REQUIRED snap_id
  # @param REQUIRED access_token
  # Authentication required
  def destroy
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    # 1. Check to make sure author of snap is current_user
    # 2. Delete Snap with snap_id in params
    
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'snap#destroy',nil,nil,api_call_duration,nil,nil,nil)
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
  end
  
  # Comment on a Snap
  # @param REQUIRED album_id
  # @param REQUIRED snap_id
  # @param REQUIRED message
  # @param REQUIRED access_token
  # Authentication required
  def comment
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    # 1. Create a new comment and associate it with the snap_id in params.
    # 2. CHECK FOR DUPES
    c = Comment.create(
      :album_id => params[:album_id],
      :snap_id => params[:snap_id],
      :user_id => @current_user.id,
      :message => params[:message]
    )

    response = {:success => "true"}
        
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'snap#comment',nil,nil,api_call_duration,nil,nil,nil)

    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
  end

  # Comment on a Snap
  # @param REQUIRED album_id
  # @param REQUIRED snap_id
  # @param REQUIRED access_token
  # Authentication required
  def like
    self.authenticate_token
    
    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    # 1. Create a new like and associate it with the snap_id in params.
    # 2. LIKES are unique, only one LIKE per authenticated user
    # (add unique index on album, snap, user composite)
    c = Like.create(
      :album_id => params[:album_id],
      :snap_id => params[:snap_id],
      :user_id => @current_user.id
    )
    
    response = {:success => "true"}
        
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'snap#like',nil,nil,api_call_duration,nil,nil,nil)
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
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
