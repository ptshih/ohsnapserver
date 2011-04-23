class LoginController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end
  
  ###
  ### Convenience Methods
  ###
  
  def find_friends_for_current_user
    last_fetched_friends = @current_user.last_fetched_friends
    
    puts "Last fetched friends before: #{last_fetched_friends}"

    # Get all friends from facebook for the current user again
    @facebook_api.find_friends_for_facebook_id(@current_user.facebook_id, last_fetched_friends)
    
    return true
  end
  
  # This API registers a new first time User from a client
  # Receives a POST with facebook_access_token from the user
  # Returns our access_token to the client along with facebook_id, name, and friends
  def register
    # Create a new user if necessary
    @facebook_api = API::FacebookApi.new(params[:facebook_access_token])
    @current_user = @facebook_api.find_user_for_facebook_access_token
    
    # Generate a random token for this user if this is the first time
    if @current_user.access_token.nil?
      @current_user.update_attribute('access_token', SecureRandom.hex(64))
    end
    
    # Setting the join time of the user
    @facebook_api.set_joined_at(@current_user.facebook_id)
    
    # Fetch content for current user
    find_friends_for_current_user
    
    # We want to send the entire friendslist hash of id, name to the client
    friend_array = Friendship.find(:all, :select=>"friend_id, friend_name", :conditions=>"user_id = #{@current_user.id}").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.friend_name}}
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
    
    # return new friends
    # We want to send the entire friendslist hash of id, name to the client
    friend_array = Friendship.find(:all, :select=>"friend_id, friend_name", :conditions=>"user_id = #{@current_user.id}").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.friend_name}}
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
