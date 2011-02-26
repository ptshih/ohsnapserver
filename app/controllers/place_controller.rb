class PlaceController < ApplicationController
  before_filter :load_facebook_api
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end

  def load_facebook_api
    @facebook_api = API::FacebookApi.new(params[:access_token])
  end

  def index
  end
  
  # Returns sorted timeline of friend's activity at this location
  def activity
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    # @current_user.facebook_id
    # params[:place_id]
    
    if params[:limit].nil?
      limit_return = 10
    else
      limit_return = params[:limit]
    end
    
    facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
    people_list = facebook_id_array.join(",")
    
    Checkin.find(:all, :select=>"tagged_users.name, checkins.created_time", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id", order_by => 'checkins.created_time DESC', limit => limit_return).each do |taggeduser|
      response_hash = {
        :name => taggeduser['name'],
        :time => taggeduser['created_time'] 
      }
      response_array << response_hash
    end
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
    
  end
  
  # Returns general information of this place
  def show
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    # params[:place_id]
    # params[:lat]
    # params[:lng]
      
    facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
    people_list = facebook_id_array.join(",")
    query = "place_id = #{params[:place_id]} and tagged_users.facebook_id in (#{people_list})"
    friend_checkins = Checkin.find(:all, :select=>"tagged_users.*", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id").count

  # Checkin.find(:all, :select=>"tagged_users.*", :conditions=> "place_id = 115681115118628 AND tagged_users.facebook_id like '100%'", :include=>:tagged_users, :joins=>"left join tagged_users on tagged_users.checkin_id = checkins.checkin_id", :order=>'created_time desc').count

    place = Place.find(:all, :conditions=> "place_id = #{params[:place_id]}").first
    #place = Place.find(:all, :conditions=> "place_id = #{place_id}").first

    # calculate the distance between params[:lat] params[:lng] and place.lat place.lng
    d2r = Math::PI/180.0
    dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
    dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
    a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
    c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
    distance = 3956.0 * c;
    
    # /place/place_id
    response_hash = {
      :place_id => place['place_id'],
      :name => place['name'],
      :lng => place['lng'],
      :lat => place['lat'],
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
    
    #puts response_array.to_json
    
    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end

  end
  
  
end
