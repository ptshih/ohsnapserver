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
  
  # This API gets a list of checkins for your you or your friends based on the who param
  # Who parameter
  # Distance param (in miles)
  # Time
  # Mode trending or timeline mode
  # (Always passed lat long)
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
    
    # Handle filters
    # People filter
    if params[:who].nil?
      filter_people = "me"
    else
      filter_people = params[:who]
    end
    
    if filter_people == "me"
      query = "checkins.facebook_id IN (#{@current_user.facebook_id}) OR tagged_users.facebook_id IN (#{@current_user.facebook_id})"
    elsif filter_people == "friends"
      # Get an array of friend_ids
      facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
      
      people_list = facebook_id_array.join(",")
      query = "checkins.facebook_id IN (#{people_list}) OR tagged_users.facebook_id IN (#{people_list})"
    else
      # String param which may contain mulitple people's ids
      query = "checkins.facebook_id IN (#{filter_people}) OR tagged_users.facebook_id IN (#{filter_people})"
    end
    
    # Distance filter
    # params[:lat], params[:lng], params[:distance]
    
    
    # Category filter

    response_array = []
    
    # Checkin.find(:all, :select=> 'app_id, checkin_id, facebook_id, message, place_id',:conditions=> "facebook_id=4804606",:group=>'app_id, checkin_id, facebook_id, message, place_id', :include=>:tagged_users, :limit=>10)

    # Checkin.find(:all, :conditions=> query, :include=>:tagged_users, :order=>'created_time desc')

    #Checkin.where(query).each do |checkin|
    # Checkin.find(:all, :conditions=> "checkins.facebook_id IN (645750651) OR tagged_users.facebook_id IN (645750651)", :include=>:tagged_users, :joins=>:tagged_users, :order=>'created_time desc')
    
    Checkin.find(:all, :select=>"DISTINCT checkins.*", :conditions=> query, :include=>:tagged_users, :joins=>"left join tagged_users on tagged_users.checkin_id = checkins.checkin_id", :order=>'created_time desc').each do |checkin|  
      if checkin['app_id'].nil?
        checkin_app_id = nil
        checkin_app_name = nil
      else
        checkin_app_id = checkin['app_id']
        checkin_app_name = checkin.app['name']
      end
      response_hash = {
        :checkin_id => checkin['checkin_id'],
        :facebook_id => checkin['facebook_id'],
        :name => checkin.user.nil? ? "Anonymous" : checkin.user['full_name'],
        :message => checkin['message'],
        :place_id => checkin['place_id'],
        :place_name => checkin.place['name'],
        :app_id => checkin_app_id,
        :app_name => checkin_app_name,
        :checkin_timestamp => Time.parse(checkin['created_time'].to_s).to_i
      }
      response_array << response_hash
    end

    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  end
  
  def show
  end

  def nearby
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    place_id_array = @facebook_api.find_places_near_location(params[:lat], params[:lng], params[:distance], nil)
    place_list = place_id_array.join(',')
    
    query = "place_id IN (#{place_list})"
    
    response_array = []
    Place.find(:all, :conditions => query).each do |place|
      # calculate the distance between params[:lat] params[:lng] and place.lat place.lng
      d2r = Math::PI/180.0
      dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
      dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
      a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
      c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
      distance = 3956.0 * c;
      
      facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
      people_list = facebook_id_array.join(",")
      query = "place_id = #{place['place_id']} and tagged_users.facebook_id in (#{people_list})"
      friend_checkins = Checkin.find(:all, :select=>"tagged_users.*", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id").count
      
      response_hash = {
        :place_id => place['place_id'],
        :name => place['name'],
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
  
end
