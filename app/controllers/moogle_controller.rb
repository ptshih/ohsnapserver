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
  
  # This API registers a new session from a client
  # Receives a POST with access_token from the user
  # This will start the API flow to grab user and friends checkins
  def session
    # this API starts a session and tells the server to fetch new checkins for the user and his friends
    # should this be a blocking call? or just let the user start playing with cached data
  
    # if last fetched date is under 10 minutes (that is facebook's throttle), don't refetch
    if not @current_user.last_fetched_checkins.nil?
      time_diff = Time.now - @current_user.last_fetched_checkins
    
      puts "Time diff #{time_diff.to_i}"
    else
      time_diff = 601
    end
    if time_diff.to_i > 1 then

      # Get all friends from facebook for the current user again
      friend_id_array = @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id)
      
      # Get all checkins for current user
      @facebook_api.find_checkins_for_facebook_id(@current_user.facebook_id)
      
      # Fire off a background job to get all friend checkins
      Delayed::Job.enqueue FriendsCheckins.new(@facebook_api, friend_id_array)
      
      # Later we want to send the entire friendslist back to the client to cache
    end
    
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
  
end
