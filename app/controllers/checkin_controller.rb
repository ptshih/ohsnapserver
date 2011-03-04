class CheckinController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # This API gets a list of checkins for you or your friends based on the who param
  # Use by Moogle Checkins (ie Checkin Feed) tabs - distance or who
  # params[:who] = deciding who to filter on; used by the "who" tab
  # params[:lat] and params[:lng] and params[:distance]= deciding distance to filter; used by "distance" tab
  # params[:since] = a unixtime that's the start time to use in filter
  # params[:until] = a unixtime that's end time to use in filter
  # params[:count]
  def index
    # "checkin": {
    #   "app_id": 6628568379,
    #   "checkin_id": 629768127509,
    #   "created_at": "2011-02-04T13:07:33Z",
    #   "created_time": "2010-12-24T00:10:56Z",
    #   "facebook_id": 4804606,
    #   "id": 35,
    #   "message": null,
    #   "place_id": 134052349946198,
    #   "updated_at": "2011-02-04T13:07:33Z"
    # }

    Rails.logger.info request.query_parameters.inspect
    
    query_filters = ""
    facebook_bounds = ""
    distance_bounds = ""
    time_bounds = ""

      
    # WHO filter
    if params[:who]=="me" || params[:who]==nil
      filter_people = "me"
      facebook_bounds = " and tagged_users.facebook_id IN (#{@current_user.facebook_id})"
    else
      filter_people = params[:who]
      if filter_people == "friends"
        # Get an array of friend_ids
        facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
        people_list = facebook_id_array.join(",")
        facebook_bounds = " and tagged_users.facebook_id IN (#{people_list})"
      else
        # String param which may contain mulitple people's ids
        facebook_bounds = " and tagged_users.facebook_id IN (#{filter_people})"
      end
    end
    query_filters += facebook_bounds
    
    # DISTANCE filter
    # params[:lat], params[:lng], params[:distance]
    if params[:distance]!=nil && params[:lng]!=nil && params[:lat]!=nil
      distance_bounds = " and (3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )) <= #{params[:distance]}"
    end
    query_filters += distance_bounds

    # TIME filter
    # pass since, then get everything > since
    if params[:since]!=nil && params[:until]==nil
      time_bounds = " and checkins.created_time>from_unixtime(#{params[:since].to_i})"
    # pass until, then get everything < until
    elsif params[:since]==nil && params[:until]!=nil
      time_bounds = " and checkins.created_time<from_unixtime(#{params[:until].to_i})"
    else
      time_bounds = ""
    end
    query_filters += time_bounds
    
    # Removes the first " and" in the conditions
    if query_filters[0,4]==" and"
      query_filters = query_filters[4,query_filters.size]
    end
    
    # LIMIT filter
    limit_count = 100
    if !params[:count].nil?
      limit_count = params[:count].to_i
    end
    
    # Store the checkin results in the hash by checkin_id, checkin_result_hash (key,value)
    recent_checkins = Hash.new
    
    Checkin.find(:all, :select=>"checkins.*, tagged_users.facebook_id as tagged_facebook_id, tagged_users.name as 'tagged_name'", :include=>:tagged_users, :conditions => query_filters, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id", :order=>'created_time desc', :limit=>limit_count).each do |checkin|
      
      if recent_checkins.has_key?(checkin['checkin_id'])
        # Store the name if it's not the author
        if checkin['facebook_id']!=checkin['tagged_facebook_id'].to_i
          recent_checkins[checkin['checkin_id']][:tagged_user_array] << checkin['tagged_name']
          recent_checkins[checkin['checkin_id']][:tagged_count] += 1
        end
      else
        if checkin['app_id'].nil?
          checkin_app_id = nil
          checkin_app_name = nil
        else
          checkin_app_id = checkin['app_id']
          checkin_app_name = checkin.app['name']
        end
        tagged_user_array = []
        tagged_count=0
        # Store the name if it's not the author
        if checkin['facebook_id']!=checkin['tagged_facebook_id'].to_i
          tagged_user_array << checkin['tagged_name']
          tagged_count +=1
        end
        checkin_hash = {
          :checkin_id => checkin['checkin_id'],
          :facebook_id => checkin['facebook_id'],
          :name => checkin.user.nil? ? "Anonymous" : checkin.user['full_name'],
          :tagged_count => tagged_count,
          :tagged_user_array => tagged_user_array,
          :message => checkin['message'],
          :place_id => checkin['place_id'],
          :place_name => checkin.place['name'],
          :app_id => checkin_app_id,
          :app_name => checkin_app_name,
          :checkin_timestamp => Time.parse(checkin['created_time'].to_s).to_i
        }
        recent_checkins[checkin['checkin_id']] = checkin_hash
      end

    end #End loop through returned checkins+tagged user results

    response_array = []
    recent_checkins.each do |checkin_id, hash_response|
      response_array << hash_response
    end

    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  end
  
  def show
  end
  
end
