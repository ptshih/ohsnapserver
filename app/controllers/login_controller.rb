class LoginController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end
  
  ###
  ### Convenience Methods
  ###
  
  def get_friends_checkins_thread(friend_id_array = nil, last_fetched_friends_checkins = nil)
    # This version just fires off a thread and immediately does the scrape
    t = Thread.new do
      @facebook_api.find_checkins_for_facebook_id_array(@current_user.facebook_id, friend_id_array, last_fetched_friends_checkins)
    end
  end
  
  def get_friends_checkins(friend_id_array = nil, last_fetched_friends_checkins = nil)
    # We need to split up the fb_friend_id_array here so that we don't hit the FB API throttle
    # 600 calls per 600 seconds (maybe get unthrottled in the future)
    
    # first we get the initial slice of IDs
    first_batch = friend_id_array.slice!(0..499)
    
    sliced_first_batch = first_batch.each_slice(50).to_a
    
    sliced_first_batch.each do |first_slice|
      @facebook_api.find_checkins_for_facebook_id_array_async(@current_user.facebook_id, first_slice, last_fetched_friends_checkins)
      
      # first_slice_checkins = QueuedCheckins.new(@current_user.access_token, @current_user.facebook_id, first_slice, last_fetched_friends_checkins)
      # first_slice_checkins.delay.get_friends_checkins_async
    end
    
    # now we slice up the remaining IDs into chunks of 500
    sliced_friend_id_array = friend_id_array.each_slice(500).to_a
    
    # @facebook_api.find_checkins_for_facebook_id_array(@current_user.facebook_id, first_slice, last_fetched_checkins)
    # [DEPRECATION] `object.send_at(time, :method)` is deprecated. Use `object.delay(:run_at => time).method
    
    # Fire off a background job to get all friend checkins
    sliced_friend_id_array.each_with_index do |slice, index|
      slice.each do |s|
        queued_checkins = QueuedCheckins.new(@facebook_access_token, @current_user.facebook_id, s, last_fetched_friends_checkins)
        delayed_time = (index+1) * 1
        queued_checkins.delay(:run_at => delayed_time.minutes.from_now).get_friends_checkins_async
      end
    end
  end
  
  def find_friends_for_current_user
    last_fetched_friends = @current_user.last_fetched_friends
    
    puts "Last fetched friends before: #{last_fetched_friends}"

    # Get all friends from facebook for the current user again
    @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
    
    return true
  end
  
  def find_feed_for_current_user
    last_fetched_feed = @current_user.last_fetched_feed
    
    puts "Last fetched feed before: #{last_fetched_feed}"

    # Get feed of current user
    # @facebook_api.find_feed_for_facebook_id(@current_user.facebook_id, last_fetched_feed)
    
    return true
  end
  
  # This API registers a new first time User from a client
  # Receives a POST with facebook_access_token from the user
  # Returns our access_token to the client along with facebook_id, name, and friends
  def register
    # Create a new user if necessary
    @facebook_api = API::FacebookApi.new(params[:facebook_access_token])
    @current_user = @facebook_api.find_user_for_facebook_access_token
    
    # Setting the join time of the user
    @facebook_api.set_joined_at(@current_user.facebook_id)
    
    # Fetch content for current user
    find_friends_for_current_user
    find_feed_for_current_user
    
    # We want to send the entire friendslist hash of id, name to the client
    friend_array = Friend.find(:all, :select=>"friend_id, friend_name", :conditions=>"facebook_id = #{@current_user.facebook_id}").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.friend_name}}
    friend_id_array = friend_array.map  do |f| f[:friend_id] end
    
    # The response should include the current user ID and name for the client to cache
    session_response_hash = {
      :access_token => @current_user.access_token,
      :facebook_id => @current_user.facebook_id,
      :name => @current_user.name,
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
    @current_user = User.find_by_access_token(params[:access_token])
    @facebook_api = API::FacebookApi.new(@current_user.facebook_access_token)
    
    # Fetch content for current user
    find_friends_for_current_user
    find_feed_for_current_user
    
    # return new friends
    # We want to send the entire friendslist hash of id, name to the client
    friend_array = Friend.find(:all, :select=>"friend_id, friend_name", :conditions=>"facebook_id = #{@current_user.facebook_id}").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.friend_name}}
    friend_id_array = friend_array.map  do |f| f[:friend_id] end
      
    # The response should include the current user ID and name for the client to cache
    session_response_hash = {
      :access_token => @current_user.access_token,
      :facebook_id => @current_user.facebook_id,
      :name => @current_user.name,
      :friends => friend_array
    }

    respond_to do |format|
      format.xml  { render :xml => session_response_hash.to_xml }
      format.json  { render :json => session_response_hash.to_json }
    end
  end
  
end
