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
  
  # This API registers a new first time User from a client
  # Receives a POST with access_token from the user
  # This will start the API flow to grab user and friends checkins
  def register
    # reset fetch_progress
    @facebook_api.update_fetch_progress(@current_user.facebook_id, 0.1) # force progress to 0
    
    last_fetched_friends = @current_user.last_fetched_friends
    last_fetched_checkins = @current_user.last_fetched_checkins
    
    puts "Last fetched friends before: #{last_fetched_friends}"
    puts "Last fetched checkins before: #{last_fetched_checkins}"
    
    # Get all friends from facebook for the current user again
    fb_friend_id_array = @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
    
    # Get all checkins for current user
    @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, last_fetched_checkins)
    
    # Fire off a background job to get all friend checkins
    Delayed::Job.enqueue FriendsCheckins.new(@current_user.access_token, @current_user.facebook_id, fb_friend_id_array, last_fetched_checkins)
    
    # We want to send the entire friendslist hash of id, name to the client
    friend_array = Friend.find(:all, :select=>"friends.friend_id, users.full_name", :conditions=>"friends.facebook_id = #{@current_user.facebook_id}", :joins=>"left join users on friends.friend_id = users.facebook_id").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.full_name}}
    
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
      
      # Get all friends from facebook for the current user again
      fb_friend_id_array = @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
      
      # Get all checkins for current user
      @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, last_fetched_checkins)
      
      # Fire off a background job to get all friend checkins
      Delayed::Job.enqueue FriendsCheckins.new(@current_user.access_token, @current_user.facebook_id, fb_friend_id_array, last_fetched_checkins)
      
      # Later we want to send the entire friendslist back to the client to cache
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
  
  def kupos
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # Query for condition where referrer=you, person being referred=your friend
    query = "select case when referMap.refer_direction='YouRF' then refer.created_time else referred.created_time end as sortColumn,
                        refer.checkin_id as you_checkin_id,
                        refer.created_time as you_created_time,
                        #{@current_user.facebook_id} as you_facebook_id,
                        'You' as you_name,
                        place.name as place_name,
                        place.place_id as place_id,
                        referred.checkin_id as checkin_id,
                        referred.created_time as created_time,
                        t.facebook_id as facebook_id,
                        t.name as name,
                        referMap.refer_direction
        from
        (select ref1.checkin_id as refer_checkin_id,
                case when ref1.created_time<fr1.created_time then min(fr1.checkin_id) else max(fr1.checkin_id) end as checkin_id,
                case when ref1.created_time<fr1.created_time then 'YouRF' else 'FRYou' end as refer_direction
        from checkins ref1
        join tagged_users ref2 on ref1.checkin_id = ref2.checkin_id and ref2.facebook_id = #{@current_user.facebook_id}
        join checkins fr1 on fr1.place_id  = ref1.place_id and ref1.created_time!=fr1.created_time
        join tagged_users fr2 on fr1.checkin_id = fr2.checkin_id
        where fr2.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
        group by 1 order by 1 desc) referMap
        join checkins refer on refer.checkin_id = referMap.checkin_id
        join places place on place.place_id = refer.place_id
        join checkins referred on referMap.checkin_id = referred.checkin_id
        join tagged_users t on referred.checkin_id = t.checkin_id
        where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
    order by 1 desc
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    while mysqlresult = mysqlresults.fetch_hash do
      if mysqlresult['refer_direction']=="YouRF"
        refer_hash = {
          :refer_checkin_id => mysqlresult['you_checkin_id'],
          :refer_created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
          :refer_facebook_id => mysqlresult['you_facebook_id'],
          :refer_name => mysqlresult['you_name'],
          :place_name => mysqlresult['place_name'],
          :place_id => mysqlresult['place_id'],
          :checkin_id => mysqlresult['checkin_id'],
          :created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
          :facebook_id => mysqlresult['facebook_id'],
          :name => mysqlresult['name']
        }
      else
        refer_hash = {
          :refer_checkin_id => mysqlresult['checkin_id'],
          :refer_created_time => Time.parse(mysqlresult['created_time'].to_s).to_i,
          :refer_facebook_id => mysqlresult['facebook_id'],
          :refer_name => mysqlresult['name'],
          :place_name => mysqlresult['place_name'],
          :place_id => mysqlresult['place_id'],
          :checkin_id => mysqlresult['you_checkin_id'],
          :created_time => Time.parse(mysqlresult['you_created_time'].to_s).to_i,
          :facebook_id => mysqlresult['you_facebook_id'],
          :name => mysqlresult['you_name']
        }        
      end
      response_array << refer_hash
    end
    mysqlresults.free
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  
  end
  
end
