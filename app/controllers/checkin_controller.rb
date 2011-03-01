class CheckinController < ApplicationController
  before_filter :load_facebook_api
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end

  def load_facebook_api
    @facebook_api = API::FacebookApi.new(params[:access_token])
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
    if params[:who]=="me" || params[:who]==nil?
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
      distance_bounds = " and (3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )) > #{params[:distance]}"
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

  # Show nearby places
  # params[:lat]
  # params[:lng]
  def nearby
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    place_id_array = @facebook_api.find_places_near_location(params[:lat], params[:lng], params[:distance], nil)
    place_list = place_id_array.join(',')
    
    limit_count = 100
    if params[:count].nil?
      limit_count = params[:count]
    end
    
    query = "place_id IN (#{place_list})"
    
    # Returns the result by order of distance, ascending
    order_statement = "3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )"
    
    response_array = []
    Place.find(:all, :conditions => query, :order=> order_statement, :limit=> limit_count).each do |place|
      # calculate the distance between params[:lat] params[:lng] and place.lat place.lng
      d2r = Math::PI/180.0
      dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
      dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
      a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
      c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
      distance = 3956.0 * c;
      
      facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
      facebook_id_array << @current_user.facebook_id
      people_list = facebook_id_array.join(",")
      query = "place_id = #{place['place_id']} and tagged_users.facebook_id in (#{people_list})"
      friend_checkins = Checkin.find(:all, :select=>"tagged_users.*", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id").count
      
      response_hash = {
        :place_id => place['place_id'],
        :place_name => place['name'],
        :street => place['street'],
        :city => place['city'],
        :state => place['state'],
        :country => place['country'],
        :zip => place['zip'],
        :phone => place['phone'],
        :checkins_count => place['checkins_count'],
        :distance => distance,
        :checkins_friend_count => friend_checkins,
        :like_count => place['like_count'],
        :attire => place['attire'],
        :website => place['website'],
        :price => place['price_range'] 
      }
      response_array << response_hash
    end
     
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  end
  
  # Show checkin trends; sort descending popularity
  # Popularity can be sorted by params[:sort] = "like_count", "checkins_count", "friend_checkins"
  # Also can be filtered by distance
  def trends
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    if params[:sort].nil?
      params[:sort] = "friend_checkins"
    end
    
    distance_filter = ""
    if params[:distance]!=nil && params[:lng]!=nil && params[:lat]!=nil
      distance_filter = " and (3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )) > #{params[:distance]}"
    end
    
    query = "select p.lat, p.lng, p.place_id as place_id, p.name as place_name, p.checkins_count , p.like_count, count(*) as friend_checkins
        from tagged_users a
        join checkins b on a.checkin_id = b.checkin_id
        join places p on p.place_id = b.place_id
        where a.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id}) 
        " + distance_filter + "
        group by 1,2,3,4
        order by #{params[:sort]} desc
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    while mysqlresult = mysqlresults.fetch_hash do
      d2r = Math::PI/180.0
      dlong = (mysqlresult['lng'].to_f - params[:lng].to_f) * d2r;
      dlat = (mysqlresult['lat'].to_f - params[:lat].to_f) * d2r;
      a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(mysqlresult['lat'].to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
      c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
      distance = 3956.0 * c;
      
      refer_hash = {
        :place_id => mysqlresult['place_id'],
        :place_name => mysqlresult['place_name'],
        :checkins_count => mysqlresult['checkins_count'],
        :like_count => mysqlresult['like_count'],
        :checkins_friend_count => mysqlresult['friend_checkins'],
        :distance => distance
      }
      response_array << refer_hash
    end
    mysqlresults.free
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
    
    
  end
  
end
