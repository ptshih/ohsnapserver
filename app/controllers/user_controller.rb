class UserController < ApplicationController
  before_filter :default_geocoordinates
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  ###
  ### Convenience Methods
  ###
  
  def get_friends_checkins_thread(friend_id_array = nil, last_fetched_checkins = nil)
    # This version just fires off a thread and immediately does the scrape
    t = Thread.new do
      @facebook_api.find_checkins_for_facebook_id_array(@current_user.facebook_id, friend_id_array, last_fetched_checkins)
    end
  end
  
  def get_friends_checkins(friend_id_array = nil, last_fetched_checkins = nil)
    # We need to split up the fb_friend_id_array here so that we don't hit the FB API throttle
    # 600 calls per 600 seconds (maybe get unthrottled in the future)
    
    # first we get the initial slice of IDs
    first_batch = friend_id_array.slice!(0..499)
    
    sliced_first_batch = first_batch.each_slice(100).to_a
    
    sliced_first_batch.each do |first_slice|
      t = Thread.new do
        @facebook_api.find_checkins_for_facebook_id_array(@current_user.facebook_id, first_slice, last_fetched_checkins)
      end
      # first_slice_checkins = QueuedCheckins.new(@current_user.access_token, @current_user.facebook_id, first_slice, last_fetched_checkins)
      # first_slice_checkins.delay.get_friends_checkins_async
    end
    
    # now we slice up the remaining IDs into chunks of 500
    sliced_friend_id_array = friend_id_array.each_slice(100).to_a
    
    # @facebook_api.find_checkins_for_facebook_id_array(@current_user.facebook_id, first_slice, last_fetched_checkins)
    # [DEPRECATION] `object.send_at(time, :method)` is deprecated. Use `object.delay(:run_at => time).method
    
    # Fire off a background job to get all friend checkins
    sliced_friend_id_array.each_with_index do |slice, index|
      queued_checkins = QueuedCheckins.new(@current_user.access_token, @current_user.facebook_id, slice, last_fetched_checkins)
      delayed_time = (index+1) * 1
      queued_checkins.delay(:run_at => delayed_time.minutes.from_now).get_friends_checkins_async
    end
  end
  
  ###
  ### API Endpoints
  ###
  
  def index
  end
  
  def show
  end
  
  def search
  end
  
  # This API registers a new first time User from a client
  # Receives a POST with access_token from the user
  # This will start the API flow to grab user and friends checkins
  def register
    last_fetched_friends = @current_user.last_fetched_friends
    last_fetched_checkins = @current_user.last_fetched_checkins
    
    puts "Last fetched friends before: #{last_fetched_friends}"
    puts "Last fetched checkins before: #{last_fetched_checkins}"
    
    # Get all friends from facebook for the current user again
    @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)

    # Get all recent checkins for current user and his/her friends
    # This API is hit to provide a fast set of data for the user to start using the app
    @facebook_api.find_recent_checkins_for_facebook_id(@current_user.facebook_id)
    
    # Get all checkins for current user
    @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, last_fetched_checkins)
    
    # We want to send the entire friendslist hash of id, name to the client
    # Get all checkins for friends of the current user
    friend_array = Friend.find(:all, :select=>"friends.friend_id, users.full_name", :conditions=>"friends.facebook_id = #{@current_user.facebook_id}", :joins=>"left join users on friends.friend_id = users.facebook_id").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.full_name}}
    friend_id_array = friend_array.map  do |f| f[:friend_id] end
    get_friends_checkins(friend_id_array, last_fetched_checkins)
    
    # The response should include the current user ID and name for the client to cache
    session_response_hash = {
      :facebook_id => @current_user.facebook_id,
      :name => @current_user.full_name,
      :friends => friend_array
    }
    
    respond_to do |format|
      format.xml  { render :xml => session_response_hash.to_xml }
      format.json  { render :json => session_response_hash.to_json }
    end
  end
  
  # This API registers a new session from a client
  # Receives a GET with access_token from the user
  # This will fire since calls for the current user
  def session
    # this API starts a session and tells the server to fetch new checkins for the user and his friends
    # should this be a blocking call? or just let the user start playing with cached data
  
    # if last fetched date is under 10 minutes (that is facebook's throttle), don't refetch
    if not @current_user.last_fetched_checkins.nil?
      time_diff = Time.now - @current_user.last_fetched_checkins
      puts "\n\nLast Session time diff #{time_diff.to_i}\n\n"
    else
      time_diff = 601
    end
    
    # Get all recent checkins for current user and his/her friends
    # This API is hit to provide a fast set of data for the user to start using the app
    @facebook_api.find_recent_checkins_for_facebook_id(@current_user.facebook_id)
    
    if time_diff.to_i > 0 then
      puts "\n\nREFETCHING\n\n"
    
      last_fetched_friends = @current_user.last_fetched_friends
      last_fetched_checkins = @current_user.last_fetched_checkins
      
      puts "Last fetched friends before: #{last_fetched_friends}"
      puts "Last fetched checkins before: #{last_fetched_checkins}"
      
      # Get all friends from facebook for the current user again with since timestamp
      @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
      
      # Get all checkins for current user
      @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, last_fetched_checkins)
      
      # # Get all checkins for friends of the current user
      friend_array = Friend.find(:all, :select=>"friends.friend_id, users.full_name", :conditions=>"friends.facebook_id = #{@current_user.facebook_id}", :joins=>"left join users on friends.friend_id = users.facebook_id").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.full_name}}
      friend_id_array = friend_array.map  do |f| f[:friend_id] end
      get_friends_checkins(friend_id_array, last_fetched_checkins)
    end
    
    # The response should include the current user ID and name for the client to cache
    session_response_hash = {
      :facebook_id => @current_user.facebook_id,
      :name => @current_user.full_name
    }
    
    respond_to do |format|
      format.xml  { render :xml => session_response_hash.to_xml }
      format.json  { render :json => session_response_hash.to_json }
    end
  end
  
  # Shows the ME profile
  # TODO: Think of storing this information elsewhere and only doing stats via updates
  # so that we don't have to traverse the entire table
  def profile
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # Total checkins
    # Unique place checkins
    # Last checkin
    # Sorted list of top places sorted by number of times you visited
    # Sorted list of top places you and your friends visited
    # Sorted list of top people who tagged you (list total times you got tagged at top)
    # Sorted list of top people you tagged (list total times you tagged others at top)    
    
    # General state of YOU
    total_checkins = 0
    total_authored = 0
    total_you_tagged = 0
    total_tagged_you = 0
    total_unique_places = 0
    friend_tagged_you_array  = []
    you_tagged_friend_array = []
    
    # Top places for you
    you_top_places_array = []
    you_total_unique_places = 0
    you_last_checkin_time = 0
    you_last_checkin_place_id = 0
    you_last_checkin_place_name = ""
    
    # Top places for you and friends
    you_friends_top_places_array = []
    you_friend_total_unique_places = 0
    you_friend_last_checkin_facebook_id = 0
    you_friend_last_checkin_full_name = ""
    you_friend_last_checkin_time = 0
    you_friend_last_checkin_place_name = ""
    you_friend_last_checkin_place_id = 0
    
    list_limit = 10
    if !params[:count].nil?
      list_limit = params[:count].to_i
    end
    
    # Returns enough information for
    # Total checkins
    # Total times you checked-in (authored)
    # Top list of people who tagged you, and total times you were tagged
    query = "select u.facebook_id, u.full_name, count(*) as checkins
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join users u on u.facebook_id = c.facebook_id
            where t.facebook_id = #{@current_user.facebook_id}
            group by 1,2
            order by 3 desc"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    list_limit_counter = 0
    while mysqlresult = mysqlresults.fetch_hash do
      total_checkins += mysqlresult['checkins'].to_i
      
      if mysqlresult['facebook_id'].to_i == @current_user.facebook_id.to_i
        total_authored += mysqlresult['checkins'].to_i
      else
        total_tagged_you += mysqlresult['checkins'].to_i
        if list_limit_counter < list_limit
          friend_tagged_you_count_hash = {
            :facebook_id => mysqlresult['facebook_id'],
            :full_name => mysqlresult['full_name'],
            :checkins => mysqlresult['checkins']
          }
          friend_tagged_you_array << friend_tagged_you_count_hash
          list_limit_counter += 1
        end
      end
           
    end
    mysqlresults.free
    
    # Top list of people you tagged, and total people you tagged
    query = "select t.facebook_id, t.name, count(*) as checkins
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            where c.facebook_id = #{@current_user.facebook_id} and t.facebook_id != #{@current_user.facebook_id}
            group by 1 order by 3 desc"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    list_limit_counter = 0
    while mysqlresult = mysqlresults.fetch_hash do
      total_you_tagged += mysqlresult['checkins'].to_i
      
      if list_limit_counter < list_limit
        you_tagged_friend_count_hash = {
          :facebook_id => mysqlresult['facebook_id'],
          :full_name => mysqlresult['name'],
          :checkins => mysqlresult['checkins']
        }
        you_tagged_friend_array << you_tagged_friend_count_hash
        list_limit_counter += 1
      end
    end
    mysqlresults.free
    
    
    # Unique places checked-in, last checked-in time and place, checkin_count
    place_queries = []
    # YOUR: Unique places checked-in, last checked-in time and place, checkin_count
    place_queries << "select p.*, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id = #{@current_user.facebook_id}
            group by 1,2
            order by checkins desc"
    # YOU AND FRIENDS: Unique places checked-in, last checked-in time and place, checkin_count
    place_queries << "select p.*, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
            group by 1,2
            order by checkins desc"
    place_queries.each_with_index do |place_query, index|
      mysqlresults = ActiveRecord::Base.connection.execute(place_query)
      list_limit_counter = 0
      
      top_places_array = []
      total_unique_places=0
      last_checkin_facebook_id = 0
      last_checkin_full_name = ""
      last_checkin_time = 0
      last_checkin_place_name = ""
      last_checkin_place_id = ""
      
      while mysqlresult = mysqlresults.fetch_hash do
        last_checkin_time_for_place = Time.parse(mysqlresult['last_checkin_time'].to_s).to_i
      
        # Finding last checkin
        if last_checkin_time_for_place > last_checkin_time
          last_checkin_time = last_checkin_time_for_place
          last_checkin_place_name = mysqlresult['name']
          last_checkin_place_id = mysqlresult['place_id']
        end
        
        # Calculate the distance between params[:lat] params[:lng] and place.lat place.lng
        distance=-1
        if !params[:lng]==nil && !params[:lat]==nil
          d2r = Math::PI/180.0
          dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
          dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
          a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
          c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
          distance = 3956.0 * c;
        end
      
        # Storing table list of top places
        total_unique_places += 1
        if list_limit_counter < list_limit      
          top_place_hash = {
            :place_id => mysqlresult['place_id'].to_s,
            :place_name => mysqlresult['name'],
            :place_picture => mysqlresult['picture'],
            :place_lng => mysqlresult['lng'],
            :place_lat => mysqlresult['lat'],
            :place_street => mysqlresult['street'],
            :place_city => mysqlresult['city'],
            :place_state => mysqlresult['state'],
            :place_country => mysqlresult['country'],
            :place_zip => mysqlresult['zip'],
            :place_phone => mysqlresult['phone'],
            :place_checkins => mysqlresult['checkins_count'],
            :place_distance => distance,
            :place_friend_checkins => mysqlresult['checkins'],
            :place_likes => mysqlresult['like_count'],
            :place_attire => mysqlresult['attire'],
            :place_website => mysqlresult['website'],
            :place_price => mysqlresult['price_range'],
            :checkins => mysqlresult['checkins'],
            :last_checkin_time => last_checkin_time_for_place
          }
          top_places_array << top_place_hash
          list_limit_counter += 1
        end
      end
      mysqlresults.free
      
      # index=0 is yours; index=1 is you and friends top places
      if index==0
        you_top_places_array = top_places_array
        you_last_checkin_time = last_checkin_time
        you_last_checkin_place_name = last_checkin_place_name
        you_last_checkin_place_id = last_checkin_place_id
        you_total_unique_places = total_unique_places
      else
        you_friends_top_places_array = top_places_array
        # you_friend_last_checkin_facebook_id (can't get using existing query)
        # you_friend_last_checkin_full_name (can't get using existing query)
        you_friend_last_checkin_time = last_checkin_time
        you_friend_last_checkin_place_name = last_checkin_place_name
        you_friend_last_checkin_place_id = last_checkin_place_id
        you_friend_total_unique_places = total_unique_places
      end
      
    end
    
    response_array = []
    
    response_array << {
      :you_last_checkin_place_id => you_last_checkin_place_id, 
      :you_last_checkin_place_name => you_last_checkin_place_name, 
      :you_last_checkin_time => you_last_checkin_time
    }
    
    response_array << {
      :total_checkins => total_checkins,
      :total_authored => total_authored,
      :you_total_unique_places => you_total_unique_places,
      :you_friend_total_unique_places => you_friend_total_unique_places
    }
    
    response_array << {
      :you_top_places_array => you_top_places_array,
      :you_friends_top_places_array => you_friends_top_places_array,
      :you_tagged_friend_array => you_tagged_friend_array,
      :friend_tagged_you_array => friend_tagged_you_array
    }
    
    # response_hash ={
    #   :you_last_checkin_time => you_last_checkin_time,
    #   :you_last_checkin_place_name => you_last_checkin_place_name,
    #   :you_last_checkin_place_id => you_last_checkin_place_id,
    #   :total_checkins => total_checkins,
    #   :total_authored => total_authored,
    #   :total_you_tagged => total_you_tagged,
    #   :total_tagged_you => total_tagged_you,
    #   :you_total_unique_places => you_total_unique_places,
    #   :you_friend_total_unique_places => you_friend_total_unique_places,
    #   :friend_tagged_you_array => friend_tagged_you_array,
    #   :you_tagged_friend_array => you_tagged_friend_array,
    #   :you_top_places_array => you_top_places_array,
    #   :you_friends_top_places_array => you_friends_top_places_array
    # }
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
    
  end
  
  def friends
  end
  
  # /users/me/places
  # same as places/:place_id/me where it gets an index
  def places
    ##
    # Getting the friend's list of the place
    ##
    query = "select distinct a.place_id, a.facebook_id, b.full_name, b.first_name
            from kupos a
            join users b on a.facebook_id = b.facebook_id
            where (a.facebook_id in (select friend_id from friends where facebook_id=#{@current_user.facebook_id})
                or b.facebook_id=#{@current_user.facebook_id})
            order by a.place_id
          "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    friend_list_of_place = []
    while place = mysqlresults.fetch_hash do
      if friend_list_of_place[place['place_id']].nil?
        friend_hash_array = []
        friend_hash = {
          :facebook_id => facebook_id,
          :full_name => full_name,
          :first_name => first_name
        }
        friend_hash_array << friend_hash
        friend_list_of_place[place['place_id']] = friend_hash_array
      else
        friend_hash = {
          :facebook_id => facebook_id,
          :full_name => full_name,
          :first_name => first_name
        }
        friend_list_of_place[place['place_id']] << friend_hash
      end
    end
    mysqlresults.free

    ##    
    # Getting the activity of the place
    ##
    query = "select place_id, count(*) as activity_count
            from kupos
            where (facebook_id in (select friend_id from friends where facebook_id=#{@current_user.facebook_id})
                or facebook_id=#{@current_user.facebook_id})
            group by 1
          "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    activity_of_place = []
    while place = mysqlresults.fetch_hash do
      activity_of_place[place['place_id']] = place['activity_count']
    end
    mysqlresults.free  

    ##
    # pass since, then get everything > since
    ##    
    if params[:since]!=nil && params[:until]==nil
      time_bounds = " and kupos.created_at>from_unixtime(#{params[:since].to_i})"
    # pass until, then get everything < until
    elsif params[:since]==nil && params[:until]!=nil
      time_bounds = " and kupos.created_at<from_unixtime(#{params[:until].to_i})"
    else
      time_bounds = ""
    end
    
    ##
    # Get the actual last kupo of a place to show on the home screen
    ##
    query = "
        select p.id as place_dbid, p.place_id, p.name as place_name, p.picture_url as place_picture_url,
              facebook_id, kupo_type, kupo_type, comment, photo_url, photo_path, a.created_at
        from kupos a
        join (
          select place_id, max(id) as id
          from kupos
          where (facebook_id in (select friend_id from friends where facebook_id=#{@current_user.facebook_id})
              or facebook_id=#{@current_user.facebook_id})
              " + time_bounds + "
          group by place_id
        ) b on a.id = b.id
        join places p on p.place_id=b.place_id
        order by a.id desc
    "
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    while kupo = mysqlresults.fetch_hash do
      response_hash = {
        :id => kupo['place_dbid'].to_s,
        :place_id => kupo['place_id'].to_s,
        :name => kupo['place_name'],
        :picture_url => kupo['place_picture_url'],
        :facebook_id => kupo['facebook_id'].to_s,
        :friend_list => friend_list_of_place[kupo['place_id']],
        :activity_count => activity_of_place[place['place_id']].to_s,
        :type => kupo['kupo_type'],
        :comment => kupo['comment'],
        :timestamp => kupo['created_at']
      }
      response_array << response_hash
    end
    mysqlresults.free
    
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
    
  end
  
  def kupos
  end
  
  def checkins
  end
  
end
