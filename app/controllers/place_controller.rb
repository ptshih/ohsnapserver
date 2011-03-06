#require 'yelp_scraper'

class PlaceController < ApplicationController
  before_filter :default_geocoordinates
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  def yelpScrape
    if params[:url]
      url = url.gsub('http://www.yelp.com','')
      render:text => YelpScraper.new.extractTermsForYelpBiz(url).to_json
    end
  end

  def default_geocoordinates
    # latitude +37.401955, longitude -121.922429
    if params[:lat].nil?
      params[:lat] = 37.401955
    end
    if params[:lng].nil?
      params[:lng] = -121.922429
    end
    if params[:distance].nil?
      params[:distance] = 1000
    end
  end
  # feed: the posts/comments feed of a particular place
  # show: the information about a place - address, lat/lng, likes, checkins etc.
  # activity: activity stream of checkins by your friends
  # top_visiting_friends: top list of friends who have visited this place

  def index
  end
  
  # Show nearby places
  # params[:lat]
  # params[:lng]
  # facebook API returns a filtered by distance list; so i don't have to filter in SQL DB
  def nearby
    Rails.logger.info request.query_parameters.inspect
    
    puts "lol: #{params}"
    
    # PLACE filter
    place_id_array = @facebook_api.find_places_near_location(params[:lat], params[:lng], params[:distance], nil)
    place_list = place_id_array.join(',')
    
    # Adds pages to all the new places
    # NOTE: DISABLE TEMPORARILY
    # @facebook_api.find_page_for_page_alias(place_id_array)
    
    # LIMIT 
    limit_count = " limit 100"
    if !params[:count].nil?
      limit_count = " limit #{params[:count]}"
    end
    
    # ORDER
    # Returns the result by order of distance, ascending
    order_statement = "3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )"
    
    query = "
      select a.*, sum(case when b.facebook_id is not null then 1 else 0 end) as friend_checkins
      from places a
      left join tagged_users b on a.place_id = b.place_id
        and (b.facebook_id in (select friend_id from friends where facebook_id=#{@current_user.facebook_id})
            or b.facebook_id=#{@current_user.facebook_id})
      where a.place_id IN (#{place_list})
      group by 1
      order by " + order_statement + limit_count
    
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    while place = mysqlresults.fetch_hash do
      # calculate the distance between params[:lat] params[:lng] and place.lat place.lng
      d2r = Math::PI/180.0
      dlong = (place['lng'].to_f - params[:lng].to_f) * d2r;
      dlat = (place['lat'].to_f - params[:lat].to_f) * d2r;
      a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place['lat'].to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
      c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
      distance = 3956.0 * c;
      
      # OPTIMIZE LATER
      yelp = Yelp.find_by_place_id(place['place_id'])
            
      response_hash = {
        :place_id => place['place_id'].to_s,
        :place_name => place['name'],
        :place_picture => place['picture_url'],
        :place_lng => place['lng'],
        :place_lat => place['lat'],
        :place_street => place['street'],
        :place_city => place['city'],
        :place_state => place['state'],
        :place_country => place['country'],
        :place_zip => place['zip'],
        :place_phone => place['phone'],
        :place_checkins => place['checkins_count'],
        :place_distance => distance,
        :place_friend_checkins => place['friend_checkins'],
        :place_likes => place['like_count'],
        :place_attire => place['attire'],
        :place_website => place['website'],
        :place_price => place['price_range'],
        :place_reviews => yelp.nil? ? 0 : yelp.review_count,
        :place_rating => yelp.nil? ? "N/A" : yelp.rating,
        :place_terms => yelp.nil? ? "N/A" : yelp.yelp_terms.map {|t| t.term }.join(','),
        :place_categories => yelp.nil? ? "N/A" : yelp.yelp_categories.map {|c| c.category }.join(',')
      }
      response_array << response_hash
    end
    mysqlresults.free
     
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  end
  
  # Show list of places your friends have gone to but you haven't
  # Sorted by number of checkins to that place
  def discover
    
    Rails.logger.info request.query_parameters.inspect

    query = "select p.place_id, p.name as place_name,
            p.lat, p.lng, p.checkins_count, p.like_count,
            count(*) as friend_checkins
      from tagged_users t
      join places p on t.place_id = p.place_id
      where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
      and t.place_id not in (select place_id from tagged_users where facebook_id = #{@current_user.facebook_id})
      group by 1,2,3,4,5,6 order by friend_checkins desc
    "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    response_array = []
    while mysqlresult = mysqlresults.fetch_hash do
      
      
      
      response_hash = {
        :place_id => mysqlresult['place_id'],
        :place_name => mysqlresult['place_name'],
        :checkins_count => mysqlresult['checkins_count'],
        :like_count => mysqlresult['like_count'],
        :checkins_friend_count => mysqlresult['friend_checkins'],
        :distance => distance
      }
      
      response_array << response_hash
    end
    
    
  end
  
  # Show checkin trends; sort descending popularity
  # Popularity can be sorted by params[:sort] = "like_count", "checkins_count", "friend_checkins"
  # Also can be filtered by distance by params[:distance] = 1 (this is in miles)
  # Also can exclude places you have been params[:exclude_places_you_been] = "true" (1 is true, 0 is false)
  # Also can limit response params[:limit] = 10
  def popular
    Rails.logger.info request.query_parameters.inspect
    
    if params[:sort].nil?
      params[:sort] = "friend_checkins"
    end
    exclude_places_you_been = ""
    if params[:exclude].to_s == "true"
      exclude_places_you_been = " and a.place_id not in (select place_id from tagged_users where facebook_id = #{@current_user.facebook_id})" 
    end
    filter_limit = " limit 10"
    if !params[:limit].nil?
      filter_limit = " limit #{params[:limit]}"
    end
    
    distance_filter = ""
    if params[:distance]!=nil && params[:lng]!=nil && params[:lat]!=nil
      distance_filter = " and (3956.0 * 2.0 * atan2( power(power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2), 0.5), power( 1.0 - power(sin((lat - #{params[:lat]}) * pi()/180.0),2) + cos(#{params[:lat]} * pi()/180.0) * cos(lat * pi()/180.0) * power(sin((lng - #{params[:lng]}) * pi()/180.0),2) , 0.5) )) <= #{params[:distance]}"
    end
    
    query = "select p.lat, p.lng, p.place_id as place_id, p.name as place_name, p.checkins_count , p.like_count, count(*) as friend_checkins
        from tagged_users a
        join places p on p.place_id = a.place_id
        where a.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id}) 
        " + distance_filter + "
        " + exclude_places_you_been + "
        group by 1,2,3,4
        order by #{params[:sort]} desc
        " + filter_limit
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
  
  def shared
    Rails.logger.info request.query_parameters.inspect
    
    facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
    people_list = facebook_id_array.join(",")
    query = "facebook_id in (#{people_list})"
    shares = Share.find(:all, :conditions=> query, :include => [ :user, :place ])
    
    response_array = []
    shares.each do |share|
      response_hash = {
        :facebook_id => share['facebook_id'],
        :name => share.user['full_name'],
        :place_name => share.place['name'],
        :place_id => share['place_id'],
        :message => share['message'],
        :timestamp => Time.parse(share['shared_at'].to_s).to_i
      }
      response_array << response_hash
    end
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
  end
  
  def followed
  end
  
  # POST: Share a single place
  def share
    Rails.logger.info request.query_parameters.inspect
    
    @facebook_api.serialize_share(params[:checkin_id], @current_user.facebook_id, params[:place_id], params[:message])
    
    response = {:success => "true"}
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
  end
  
  
  #
  # SINGLE PLACE APIs
  #
  
  # Place Yelp Reviews
  def reviews
    
    response_array = []
    
    place = Place.find_by_place_id(params[:place_id])
    
    if place.yelp.nil?
      place.scrape_yelp
    end
    
    if !place.yelp.nil?
      reviews_array = place.yelp.yelp_reviews
    end
    
    if !reviews_array.nil?
      reviews_array.each do |r|
        review_hash = {
          :yelp_pid => r.yelp_pid,
          :rating => r.rating,
          :text => r.text
        }
        response_array << review_hash
      end
    end
    
    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end
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
    @facebook_api.find_place_post_for_place_id(params[:place_id])
    
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
        :facebook_id => taggeduser['facebook_id'].to_s,
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
  def topvisitors
    Rails.logger.info request.query_parameters.inspect
    
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

    # params[:place_id]
    # params[:lat]
    # params[:lng]
      
    facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
    people_list = facebook_id_array.join(",")
    query = "checkins.place_id = #{params[:place_id]} and tagged_users.facebook_id in (#{people_list})"
    friend_checkins = Checkin.find(:all, :select=>"tagged_users.*", :conditions=> query, :include=>:tagged_users, :joins=>"join tagged_users on tagged_users.checkin_id = checkins.checkin_id").count

  # Checkin.find(:all, :select=>"tagged_users.*", :conditions=> "place_id = 115681115118628 AND tagged_users.facebook_id like '100%'", :include=>:tagged_users, :joins=>"left join tagged_users on tagged_users.checkin_id = checkins.checkin_id", :order=>'created_time desc').count

    place = Place.find(:all, :conditions=> "place_id = #{params[:place_id]}").first
    #place = Place.find(:all, :conditions=> "place_id = #{place_id}").first
    
    # @facebook_api.find_page_for_page_alias(["#{place.page_parent_alias}"])
    # place = Place.find(:all, :conditions=> "place_id = #{params[:place_id]}").first    

    # calculate the distance between params[:lat] params[:lng] and place.lat place.lng
    d2r = Math::PI/180.0
    dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
    dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
    a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
    c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
    distance = 3956.0 * c;
    
    # OPTIMIZE LATER
    yelp = Yelp.find_by_place_id(place['place_id'])
    
    # /place/place_id
    response_hash = {
      :place_id => place['place_id'].to_s,
      :place_name => place['name'],
      :place_picture => place['picture_url'],
      :place_lng => place['lng'],
      :place_lat => place['lat'],
      :place_street => place['street'],
      :place_city => place['city'],
      :place_state => place['state'],
      :place_country => place['country'],
      :place_zip => place['zip'],
      :place_phone => place['phone'],
      :place_checkins => place['checkins_count'],
      :place_distance => distance,
      :place_friend_checkins => friend_checkins,
      :place_likes => place['like_count'],
      :place_attire => place['attire'],
      :place_website => place['website'],
      :place_price => place['price_range'],
      :place_reviews => place.yelp.nil? ? 0 : place.yelp.review_count,
      :place_rating => place.yelp.nil? ? "N/A" : place.yelp.rating,
      :place_terms => yelp.nil? ? "N/A" : yelp.yelp_terms.map {|t| t.term }.join(','),
      :place_categories => yelp.nil? ? "N/A" : yelp.yelp_categories.map {|c| c.category }.join(',')
    }
    
    #puts response_array.to_json
    
    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end

  end
  
  
end
