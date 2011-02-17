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
    
    u = User.select('last_fetched_checkins, last_fetched_friends').where("facebook_id = #{@current_user.facebook_id}").first
    
    
    has_fetched_friends_before = !u.last_fetched_friends.nil?
    has_fetched_checkins_before = !u.last_fetched_checkins.nil?
    
    puts "Has fetched friends before: #{has_fetched_friends_before}"
    puts "Has fetched checkins before: #{has_fetched_checkins_before}"
    
    # Get all friends from facebook for the current user again
    fb_friend_id_array = @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, has_fetched_friends_before)
    
    # Get all checkins for current user
    @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, has_fetched_checkins_before)
    
    # Fire off a background job to get all friend checkins
    Delayed::Job.enqueue FriendsCheckins.new(@current_user.access_token, @current_user.facebook_id, fb_friend_id_array, has_fetched_checkins_before)
    
    # Later we want to send the entire friendslist back to the client to cache
    friend_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id.to_i}
    
    # The response should include the current user ID and name for the client to cache
    session_response_hash = {
      :facebook_id => @current_user.facebook_id,
      :name => @current_user.full_name,
      :friends => friend_id_array
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

      # Get all friends from facebook for the current user again
      fb_friend_id_array = @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, true)
      
      # Get all checkins for current user
      @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id, true)
      
      # Fire off a background job to get all friend checkins
      Delayed::Job.enqueue FriendsCheckins.new(@current_user.access_token, @current_user.facebook_id, fb_friend_id_array, true)
      
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
    
    progress_response = User.select('fetch_progress').where("facebook_id = #{@current_user.facebook_id}").map {|u| u.fetch_progress.to_f}
    
    progress_response_hash = {
      :progress => progress_response.first.to_f
    }
    respond_to do |format|
      format.xml  { render :xml => progress_response_hash.to_xml }
      format.json  { render :json => progress_response_hash.to_json }
    end
  end
  
end
