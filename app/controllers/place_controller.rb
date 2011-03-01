class PlaceController < ApplicationController
  before_filter :load_facebook_api
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end

  # feed: the posts/comments feed of a particular place
  # show: the information about a place - address, lat/lng, likes, checkins etc.
  # activity: activity stream of checkins by your friends
  # top_visiting_friends: top list of friends who have visited this place
  
  def load_facebook_api
    @facebook_api = API::FacebookApi.new(params[:access_token])
  end

  def index
  end
  
  # Returns a time sorted stream of posts made to that place
  def feed
    Rails.logger.info request.query_parameters.inspect
    
    if params[:limit].nil?
      limit_return = 20
    else
      limit_return = params[:limit]
    end
    
    # Serializing the posts for that place
    API::FacebookApi.new.find_place_post_for_place_id(params[:place_id])
    
    response_array = []
    
    PlacePost.find(:all, :conditions=>"place_id=#{params[:place_id]} and post_type='status'", :order => "post_created_time desc", :limit => limit_return).each do |feed|
      response_hash = {
        :post_created_time => feed['post_created_time'],
        :from_id=> feed['from_id'],
        :from => feed['from_name'],
        :message => feed['message']
      }
      response_array << response_hash
    end
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  
  end
  
  # Returns sorted timeline of friend's activity at this location
  def activity
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    # @current_user.facebook_id
    # params[:place_id]
    
    if params[:limit].nil?
      limit_return = 50
    else
      limit_return = params[:limit]
    end
    
    facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
    facebook_id_array << @current_user.facebook_id
    people_list = facebook_id_array.join(",")
    query = "checkins.place_id=#{params[:place_id]} AND (tagged_users.facebook_id IN (#{people_list}))"
    
    response_array = []
    
    Checkin.find(:all, :select=>"tagged_users.name, tagged_users.facebook_id, checkins.created_time, checkins.checkin_id, checkins.message", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id", :order => 'checkins.created_time DESC', :limit => limit_return).each do |taggeduser|
      response_hash = {
        :facebook_id => taggeduser['facebook_id'],
        :message => taggeduser['message'],
        :place_name => taggeduser['name'],
        :timestamp => Time.parse(taggeduser['created_time'].to_s).to_i
      }
      response_array << response_hash
    end
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
    
  end
  
  # Top visiting friends of this particular location
  # top_visiting_friends(place_id)
  def top_visiting_friends
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    query = "select a.facebook_id as friend_facebook_id, a.name as friend_name, count(*) as checkins
            from tagged_users a
            join checkins b on a.checkin_id = b.checkin_id and b.place_id = #{params[:place_id]}
            join places p on p.place_id = b.place_id
            where a.facebook_id = #{@current_user.facebook_id}
              or a.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
            group by 1,2
            order by 3 desc, 2"
    
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    rank = 0
    while mysqlresult = mysqlresults.fetch_hash do
      rank += 1
      refer_hash = {
        :rank => rank,
        :friend_facebook_id => mysqlresult['friend_facebook_id'],
        :friend_name => mysqlresult['friend_name'],
        :checkins_count => mysqlresult['checkins_count']
      }
      response_array << refer_hash
    end
    mysqlresults.free
    
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
      :place_name => place['name'],
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
