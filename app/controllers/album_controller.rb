class AlbumController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    # controller.authenticate_token # sets the @current_user var based on passed in access_token
  end

  # Show a list of albums for the authenticated user (or optionally any user if public)
  # @param REQUIRED list_type "all", "contributing"
  # @param REQUIRED access_token
  # @param OPTIONAL user_id (future filter for public streams, maybe)
  # Authentication required
  def index
    self.authenticate_token

    Rails.logger.info request.query_parameters.inspect
    api_call_start = Time.now.to_f
    
    ### TODO ###
    # We should also provide a participants list for each album

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

    # Filter to show only albums where you are contributing
    album_id_array = []
    if params[:list_type] == 'contributing'
      query = "select album_id from albums_users where user_id = #{@current_user.id}"
    # show all albums of your first degree connections
    else
      query = " select album_id
                from albums_users
                where user_id in (select friend_id from friendships where user_id=#{@current_user.id})
                  or user_id=#{@current_user.id}"
    end
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      album_id_array << row['album_id']
    end
    
    #
    # WARNING!!!
    # CHECK FOR EMPTY ARRAY
    # DEFAULT TO "0" for now
    if album_id_array.length==0
      album_id_array << "0"
    end
    album_id_string = album_id_array.uniq.join(',')
    puts "this is the album #{album_id_string}"
    
    ###
    # Getting participants
    ###
    participants_hash = {}

    # Prepare Query
    query = "
      select au.album_id, u.id, u.name, u.first_name, u.picture_url
      from albums_users au
      join users u on au.user_id = u.id
      where au.album_id in (#{album_id_string})
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
    # Getting album stats
    # comments, likes
    ###
    album_stats = { 'comment'=>{}, 'like'=>{}}
    query = "select album_id, count(*) as thecount from snap_comments group by 1"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      album_stats['comment'][row['album_id'].to_s]=row['thecount']
    end
    query = "select album_id, count(*) as thecount from snap_likes group by 1"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      album_stats['like'][row['album_id'].to_s]=row['thecount']
    end
    
    ###
    # Getting albums
    ###

    # Prepare Query
    query = "
      select
        a.id, a.last_snap_id, a.name, s.user_id, u.name as 'user_name', u.picture_url,
        s.message, s.media_type, s.photo_file_name, s.lat, s.lng, a.updated_at,
        sum(case when s.media_type='photo' then 1 else 0 end) as photo_count,
        sum(case when s.media_type='video' then 1 else 0 end) as video_count
      from albums a
      join snaps s on a.last_snap_id = s.id
      join users u on u.id = s.user_id
      join snaps s2 on s2.album_id = a.id
      where a.id in (#{album_id_string})
      group by 1
    "
    
    # Fetch Results
    # http://s3.amazonaws.com/kupo/kupos/photos/".$places[$key]['id']."/original/".$places[$key]['photo_file_name']
    # short square photo size; figure out how to pass this size later
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      # Each response hash consists of album id, name, and last_snap details flattened
      row_hash = {
        :id => row['id'].to_s, # album id
        :name => row['name'], # album name
        :user_id => row['user_id'].to_s, # last_snap user id
        :user_name => row['user_name'], # last_snap user name
        :user_picture_url => row['picture_url'], #last_snap user picture url (facebook or google)
        :message => row['message'], # last_snap message
        :photo_url => "#{S3_BASE_URL}/photos/#{row['last_snap_id']}/thumb/#{row['photo_file_name']}",
        :media_type => row['media_type'], # last_snap type
        :photo_count => 0, # TODO
        :video_count => 0, # TODO
        :like_count => album_stats['like'][row['id'].to_s].nil? ? 0 : album_stats['like'][row['id'].to_s],
        :comment_count => album_stats['comment'][row['id'].to_s].nil? ? 0 : album_stats['comment'][row['id'].to_s],
        :lat => row['lat'],
        :lng => row['lng'],
        :participants => participants_hash[row['album_id'].to_s], # list of participants for this album
        :timestamp => row['updated_at'].to_i # album updated_at
      }
      response_array << row_hash
    end

    # Paging
    paging_hash = {}
    paging_hash[:since] = response_array.first[:timestamp].nil? ? Time.now.to_i : response_array.first[:timestamp]
    paging_hash[:until] = response_array.last[:timestamp].nil? ? Time.now.to_i : response_array.first[:timestamp]
    
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
  # TODO construct FB post back to wall with tagged list
  # @param REQUIRED name
  # @param REQUIRED tagged (comma separated of user ids)
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

    # Create the album
    album = Album.create(
      :name => params[:name]
    )
    
    # Create the snap
    if params[:snap_type]='video'
      params[:video]=params[:media]
    elsif params[:snap_type]='photo'
      params[:photo]=params[:media]
    else
    end
    s = Snap.create(
      :album_id => album.id,
      :media_type => params[:media_type],
      :user_id => @current_user.id,
      :photo => params[:photo],
      :video => params[:video],
      :message => params[:message]  
    )
    
    # Update the album with last snap_id
    album.update_attribute(:last_snap_id, s.id)
    
    # Update user last snap_id
    u = User.find_by_id(@current_user.id)
    u.update_attribute(:last_snap_id, s.id)

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
    if params[:media_type].nil?
    elsif params[:media_type]=="video_only"
      content_type_conditions = " AND has_video=1"
    elsif params[:media_type]=="photo_only"
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
    if params[:media_type].nil?
    elsif params[:media_type]=="video_only"
      set_conditions = "event_id = #{params[:event_id]} AND has_video=1"
    elsif params[:media_type]=="photo_only"
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
            "name" : "LoL Cats",
            "photo_urls" : [
              "http://cache.ohinternet.com/images/b/b0/Lolcat.JPG",
              "http://1.bp.blogspot.com/_-wOg-YptAFo/TTH69itIwHI/AAAAAAAAAOo/TbUL3_H8dG8/s1600/fix%2Bcomputer.jpg",
              "http://www.lunkos.com/wp-content/uploads/2009/11/schrodinger_s-lolcat.jpg",
              "http://randomizingtheweb.files.wordpress.com/2011/04/happy_lolcat.jpg",
              "http://images1.fanpop.com/images/photos/1600000/LOLcats-animal-humor-1664702-400-400.jpg"
            ],
            "photo_count" : 7,
            "participants" : "Peter S, Tom L, Nate B, and 7 more...",
            "timestamp" : 1305621455
          },
          {
            "id" : "2",
            "name" : "Expensive Cars",
            "photo_urls" : [
              "http://www.cartype.com/pics/3632/small/audi_r8_led-lights_08.jpg",
              "http://www.audi-r8-q7.com/images/audi-r8-1.jpg",
              "http://www.tuningnews.net/news/071116d/ppi_audi_r8.jpg",
              "http://www.blogcdn.com/green.autoblog.com/media/2008/01/r8-v12-tdi450.jpg",
              "http://www.autospectator.com/cars/files/images/AU_2308_s.jpg"
            ],
            "photo_count" : 53,
            "participants" : "Peter S, Tom L, Nate B, and 27 more...",
            "timestamp" : 1300910808
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
