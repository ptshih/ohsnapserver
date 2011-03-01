class MoogleController < ApplicationController
  before_filter :load_facebook_api
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  def load_facebook_api
    @facebook_api = API::FacebookApi.new(params[:access_token])
  end
  
  def get_friends_checkins(friend_id_array = nil, last_fetched_checkins = nil)
    # We need to split up the fb_friend_id_array here so that we don't hit the FB API throttle
    # 600 calls per 600 seconds
    
    # first we get the initial slice of IDs
    first_batch = friend_id_array.slice!(0..499)
    
    sliced_first_batch = first_batch.each_slice(100).to_a
    
    sliced_first_batch.each do |first_slice|
      first_slice_checkins = QueuedCheckins.new(@current_user.access_token, @current_user.facebook_id, first_slice, last_fetched_checkins)
      first_slice_checkins.delay.get_friends_checkins_async
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
    friend_array = Friend.find(:all, :select=>"friends.friend_id, users.full_name", :conditions=>"friends.facebook_id = #{@current_user.facebook_id}", :joins=>"left join users on friends.friend_id = users.facebook_id").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.full_name}}
    friend_id_array = friend_array.map  do |f| f[:friend_id] end
      
    # Get all checkins for friends of the current user
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
    
      puts "\n\nTime diff #{time_diff.to_i}\n\n"
    else
      time_diff = 601
    end
    
    if time_diff.to_i > 600 then
      puts "\n\nREFETCHING\n\n"
    
      last_fetched_friends = @current_user.last_fetched_friends
      last_fetched_checkins = @current_user.last_fetched_checkins
      
      puts "Last fetched friends before: #{last_fetched_friends}"
      puts "Last fetched checkins before: #{last_fetched_checkins}"
      
      # Get all friends from facebook for the current user again with since timestamp
      @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
      
      # Get all recent checkins for current user and his/her friends
      # This API is hit to provide a fast set of data for the user to start using the app
      @facebook_api.find_recent_checkins_for_facebook_id(@current_user.facebook_id)
      
      # Get all checkins for current user
      @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, last_fetched_checkins)
      
      friend_array = Friend.find(:all, :select=>"friends.friend_id, users.full_name", :conditions=>"friends.facebook_id = #{@current_user.facebook_id}", :joins=>"left join users on friends.friend_id = users.facebook_id").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.full_name}}
      friend_id_array = friend_array.map  do |f| f[:friend_id] end
        
      # Get all checkins for friends of the current user
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
  
  def progress
    # DEPRECATED
    # This is a ghetto-temporary API used to poll the progress of the server when an FULL FETCH occurs
    # Eventually we should really use a persistent connection here between client and server
    
    progress_response_hash = {
      :progress => @current_user.fetch_progress.to_f
    }
    respond_to do |format|
      format.xml  { render :xml => progress_response_hash.to_xml }
      format.json  { render :json => progress_response_hash.to_json }
    end
  end
  
  # Shows the ME profile
  # TODO: Think of storing this information elsewhere and only doing stats via updates
  # so that we don't have to traverse the entire table
  def me
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
    friend_tagged_you_count_array  = []
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
          friend_tagged_you_count_array << friend_tagged_you_count_hash
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
    place_queries << "select p.place_id, p.name as place_name, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id = #{@current_user.facebook_id}
            group by 1,2
            order by 4 desc"
    # YOU AND FRIENDS: Unique places checked-in, last checked-in time and place, checkin_count
    place_queries << "select p.place_id, p.name as place_name, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
            group by 1,2
            order by 4 desc"
    place_queries.each do |index, place_query| 
      mysqlresults = ActiveRecord::Base.connection.execute(place_query)
      list_limit_counter = 0
      
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
          last_checkin_place_name = mysqlresult['place_name']
          last_checkin_place_id = mysqlresult['place_id']
        end
      
        # Storing table list of top places
        total_unique_places += 1
        if list_limit_counter < list_limit      
          top_place_hash = {
            :place_id => mysqlresult['place_id'],
            :place_name => mysqlresult['place_name'],
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
    
    response_hash ={
      :facebook_id => @current_user.facebook_id,
      :you_last_checkin_time => last_checkin_time,
      :you_last_checkin_place_name => last_checkin_place_name,
      :you_last_checkin_place_id => last_checkin_place_id,
      :total_checkins => total_checkins,
      :total_authored => total_authored,
      :total_you_tagged => total_you_tagged,
      :total_tagged_you => total_tagged_you,
      :you_total_unique_places => you_total_unique_places,
      :you_friend_total_unique_places => you_friend_total_unique_places,
      :friend_tagged_you_count_array => friend_tagged_you_count_array,
      :you_tagged_friend_array => you_tagged_friend_array,
      :you_top_places_array => you_top_places_array,
      :you_friends_top_places_array => you_friends_top_places_array
    }
    
    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end
    
  end
  
  # Shows the ME timeline
  def kupos
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # Query for condition where we're showing referrals (YouRF or FRYou ie You referred Friend or Friend referred You)
    # NOT USED FOR NOW
    # query = "select case when referMap.refer_direction='YouRF' then refer.created_time else referred.created_time end as sortColumn,
    #                         refer.checkin_id as you_checkin_id,
    #                         refer.created_time as you_created_time,
    #                         #{@current_user.facebook_id} as you_facebook_id,
    #                         'You' as you_name,
    #                         place.name as place_name,
    #                         place.place_id as place_id,
    #                         referred.checkin_id as checkin_id,
    #                         referred.created_time as created_time,
    #                         t.facebook_id as facebook_id,
    #                         t.name as name,
    #                         referMap.refer_direction
    #         from
    #         (select ref1.checkin_id as refer_checkin_id,
    #                 case when ref1.created_time<fr1.created_time then min(fr1.checkin_id) else max(fr1.checkin_id) end as checkin_id,
    #                 case when ref1.created_time<fr1.created_time then 'YouRF' else 'FRYou' end as refer_direction
    #         from checkins ref1
    #         join tagged_users ref2 on ref1.checkin_id = ref2.checkin_id and ref2.facebook_id = #{@current_user.facebook_id}
    #         join checkins fr1 on fr1.place_id  = ref1.place_id and ref1.created_time!=fr1.created_time
    #         join tagged_users fr2 on fr1.checkin_id = fr2.checkin_id
    #         where fr2.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
    #         group by 1 order by 1 desc) referMap
    #         join checkins refer on referMap.refer_checkin_id = refer.checkin_id
    #         join places place on place.place_id = refer.place_id
    #         join checkins referred on referMap.checkin_id = referred.checkin_id
    #         join tagged_users t on referred.checkin_id = t.checkin_id
    #         where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
    #     order by 1 desc
    #     "    
    #     mysqlresults = ActiveRecord::Base.connection.execute(query)
    #     response_array = []
    #     while mysqlresult = mysqlresults.fetch_hash do
    #       if mysqlresult['refer_direction']=="YouRF"
    #         refer_hash = {
    #           :refer_checkin_id => mysqlresult['you_checkin_id'],
    #           :refer_created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
    #           :refer_facebook_id => mysqlresult['you_facebook_id'],
    #           :refer_name => mysqlresult['you_name'],
    #           :place_name => mysqlresult['place_name'],
    #           :place_id => mysqlresult['place_id'],
    #           :checkin_id => mysqlresult['checkin_id'],
    #           :created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
    #           :facebook_id => mysqlresult['facebook_id'],
    #           :name => mysqlresult['name']
    #         }
    #       else
    #         refer_hash = {
    #           :refer_checkin_id => mysqlresult['checkin_id'],
    #           :refer_created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
    #           :refer_facebook_id => mysqlresult['facebook_id'],
    #           :refer_name => mysqlresult['name'],
    #           :place_name => mysqlresult['place_name'],
    #           :place_id => mysqlresult['place_id'],
    #           :checkin_id => mysqlresult['you_checkin_id'],
    #           :created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
    #           :facebook_id => mysqlresult['you_facebook_id'],
    #           :name => mysqlresult['you_name']
    #         }        
    #       end
    #       response_array << refer_hash
    #     end
    #     mysqlresults.free
    
    # Paging parameter require time bounds and limit
    time_bounds = ""
    if params[:since]!=nil && params[:until]==nil
      time_bounds = " and c.created_time>from_unixtime(#{params[:since].to_i})"
    # pass until, then get everything < until
    elsif params[:since]==nil && params[:until]!=nil
      time_bounds = " and c.created_time<from_unixtime(#{params[:until].to_i})"
    else
    end
    limit_count = " limit 100"
    if !params[:count].nil?
      limit_count = " limit #{params[:count]}"
    end
    
    # Following places that you've checked-in to in the last month
    query = "select  p.place_id, p.name as place_name,
            you_t.facebook_id as your_facebook_id,
            c.created_time as checkin_time,
            t.facebook_id,
            t.name,
            max(you_c.created_time) as your_last_checkin_time
      from checkins you_c
      join tagged_users you_t on you_c.checkin_id = you_t.checkin_id and you_t.facebook_id = #{@current_user.facebook_id}
      join checkins c on you_c.place_id = c.place_id " + time_bounds + "
      join tagged_users t on c.checkin_id = t.checkin_id
          and (t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id}) or t.facebook_id = #{@current_user.facebook_id})
      join places p on p.place_id = c.place_id
      where you_c.created_time>=date_add(now(), interval - 1 month)
    group by 1,2,3,4,5,6
    order by 4 desc
    " + limit_count
    
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    while mysqlresult = mysqlresults.fetch_hash do
      if mysqlresult['facebook_id']==mysqlresult['your_facebook_id'] && mysqlresult['your_last_checkin_time']==mysqlresult['checkin_time']
        #Ignore entries where your most recent checkin IS that actual checkin
      else
        refer_hash = {
          :checkin_time => Time.parse(mysqlresult['checkin_time'].to_s).to_i,
          :place_id => mysqlresult['place_id'],
          :place_name => mysqlresult['place_name'],
          :user_facebook_id => mysqlresult['facebook_id'],
          :user_name => mysqlresult['name'],
          :your_last_checkin_time => Time.parse(mysqlresult['your_last_checkin_time'].to_s).to_i,
          :your_facebook_id => mysqlresult['your_facebook_id']
        }
        response_array << refer_hash
      end
    end
    mysqlresults.free
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  
  end
  
end
