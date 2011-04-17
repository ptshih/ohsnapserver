class UserController < ApplicationController
  before_filter :default_geocoordinates
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end

  ###
  ### API Endpoints
  ###

  def index
  end

  def show
  end

  def search
  end

  # Shows the ME profile
  # TODO: Think of storing this information elsewhere and only doing stats via updates
  # so that we don't have to traverse the entire table
  def profile
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"

    # Total checkins
    # Unique place checkins
    # Last checkin
    # Sorted list of top places sorted by number of times you visited
    # Sorted list of top places you and your friends visited
    # Sorted list of top people who tagged you (list total times you got tagged at top)
    # Sorted list of top people you tagged (list total times you tagged others at top)

    # General state of YOU
    total_checkins = 0
    total_authored = 0
    total_you_tagged = 0
    total_tagged_you = 0
    total_unique_places = 0
    friend_tagged_you_array  = []
    you_tagged_friend_array = []

    # Top places for you
    you_top_places_array = []
    you_total_unique_places = 0
    you_last_checkin_time = 0
    you_last_checkin_place_id = 0
    you_last_checkin_place_name = ""

    # Top places for you and friends
    you_friends_top_places_array = []
    you_friend_total_unique_places = 0
    you_friend_last_checkin_facebook_id = 0
    you_friend_last_checkin_full_name = ""
    you_friend_last_checkin_time = 0
    you_friend_last_checkin_place_name = ""
    you_friend_last_checkin_place_id = 0

    list_limit = 10
    if !params[:count].nil?
      list_limit = params[:count].to_i
    end

    # Returns enough information for
    # Total checkins
    # Total times you checked-in (authored)
    # Top list of people who tagged you, and total times you were tagged
    query = "select u.facebook_id, u.full_name, count(*) as checkins
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join users u on u.facebook_id = c.facebook_id
            where t.facebook_id = #{@current_user.facebook_id}
            group by 1,2
            order by 3 desc"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    list_limit_counter = 0

    mysqlresults.each(:as => :hash) do |row|
      total_checkins += row['checkins'].to_i

      if row['facebook_id'].to_i == @current_user.facebook_id.to_i
        total_authored += row['checkins'].to_i
      else
        total_tagged_you += row['checkins'].to_i
        if list_limit_counter < list_limit
          friend_tagged_you_count_hash = {
            :facebook_id => row['facebook_id'],
            :full_name => row['full_name'],
            :checkins => row['checkins']
          }
          friend_tagged_you_array << friend_tagged_you_count_hash
          list_limit_counter += 1
        end
      end

    end

    # Top list of people you tagged, and total people you tagged
    query = "select t.facebook_id, t.name, count(*) as checkins
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            where c.facebook_id = #{@current_user.facebook_id} and t.facebook_id != #{@current_user.facebook_id}
            group by 1 order by 3 desc"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    list_limit_counter = 0
    mysqlresults.each(:as => :hash) do |row|
      total_you_tagged += row['checkins'].to_i

      if list_limit_counter < list_limit
        you_tagged_friend_count_hash = {
          :facebook_id => row['facebook_id'],
          :full_name => row['name'],
          :checkins => row['checkins']
        }
        you_tagged_friend_array << you_tagged_friend_count_hash
        list_limit_counter += 1
      end
    end


    # Unique places checked-in, last checked-in time and place, checkin_count
    place_queries = []
    # YOUR: Unique places checked-in, last checked-in time and place, checkin_count
    place_queries << "select p.*, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id = #{@current_user.facebook_id}
            group by 1,2
            order by checkins desc"
    # YOU AND FRIENDS: Unique places checked-in, last checked-in time and place, checkin_count
    place_queries << "select p.*, max(c.created_time) as 'last_checkin_time', count(*) as 'checkins'
            from checkins c
            join tagged_users t on c.checkin_id = t.checkin_id
            join places p on p.place_id = c.place_id
            where t.facebook_id in (select friend_id from friends where facebook_id = #{@current_user.facebook_id})
            group by 1,2
            order by checkins desc"
    place_queries.each_with_index do |place_query, index|
      mysqlresults = ActiveRecord::Base.connection.execute(place_query)
      list_limit_counter = 0

      top_places_array = []
      total_unique_places=0
      last_checkin_facebook_id = 0
      last_checkin_full_name = ""
      last_checkin_time = 0
      last_checkin_place_name = ""
      last_checkin_place_id = ""

      mysqlresults.each(:as => :hash) do |row|
        last_checkin_time_for_place = row['last_checkin_time'].to_i

        # Finding last checkin
        if last_checkin_time_for_place > last_checkin_time
          last_checkin_time = last_checkin_time_for_place
          last_checkin_place_name = row['name']
          last_checkin_place_id = row['place_id']
        end

        # Calculate the distance between params[:lat] params[:lng] and place.lat place.lng
        distance=-1
        if !params[:lng]==nil && !params[:lat]==nil
          d2r = Math::PI/180.0
          dlong = (place.lng.to_f - params[:lng].to_f) * d2r;
          dlat = (place.lat.to_f - params[:lat].to_f) * d2r;
          a = (Math.sin(dlat/2.0))**2.0 + Math.cos(params[:lat].to_f*d2r) * Math.cos(place.lat.to_f*d2r) * (Math.sin(dlong/2.0))**2.0;
          c = 2.0 * Math.atan2(a**(1.0/2.0), (1.0-a)**(1.0/2.0));
          distance = 3956.0 * c;
        end

        # Storing table list of top places
        total_unique_places += 1
        if list_limit_counter < list_limit
          top_place_hash = {
            :place_id => row['place_id'].to_s,
            :place_name => row['name'],
            :place_picture => row['picture'],
            :place_lng => row['lng'],
            :place_lat => row['lat'],
            :place_street => row['street'],
            :place_city => row['city'],
            :place_state => row['state'],
            :place_country => row['country'],
            :place_zip => row['zip'],
            :place_phone => row['phone'],
            :place_checkins => row['checkin_count'],
            :place_distance => distance,
            :place_friend_checkins => row['checkins'],
            :place_likes => row['like_count'],
            :place_attire => row['attire'],
            :place_website => row['website'],
            :place_price => row['price_range'],
            :checkins => row['checkins'],
            :last_checkin_time => last_checkin_time_for_place
          }
          top_places_array << top_place_hash
          list_limit_counter += 1
        end
      end

      # index=0 is yours; index=1 is you and friends top places
      if index==0
        you_top_places_array = top_places_array
        you_last_checkin_time = last_checkin_time
        you_last_checkin_place_name = last_checkin_place_name
        you_last_checkin_place_id = last_checkin_place_id
        you_total_unique_places = total_unique_places
      else
        you_friends_top_places_array = top_places_array
        # you_friend_last_checkin_facebook_id (can't get using existing query)
        # you_friend_last_checkin_full_name (can't get using existing query)
        you_friend_last_checkin_time = last_checkin_time
        you_friend_last_checkin_place_name = last_checkin_place_name
        you_friend_last_checkin_place_id = last_checkin_place_id
        you_friend_total_unique_places = total_unique_places
      end

    end

    response_array = []

    response_array << {
      :you_last_checkin_place_id => you_last_checkin_place_id,
      :you_last_checkin_place_name => you_last_checkin_place_name,
      :you_last_checkin_time => you_last_checkin_time
    }

    response_array << {
      :total_checkins => total_checkins,
      :total_authored => total_authored,
      :you_total_unique_places => you_total_unique_places,
      :you_friend_total_unique_places => you_friend_total_unique_places
    }

    response_array << {
      :you_top_places_array => you_top_places_array,
      :you_friends_top_places_array => you_friends_top_places_array,
      :you_tagged_friend_array => you_tagged_friend_array,
      :friend_tagged_you_array => friend_tagged_you_array
    }

    # response_hash ={
    #   :you_last_checkin_time => you_last_checkin_time,
    #   :you_last_checkin_place_name => you_last_checkin_place_name,
    #   :you_last_checkin_place_id => you_last_checkin_place_id,
    #   :total_checkins => total_checkins,
    #   :total_authored => total_authored,
    #   :total_you_tagged => total_you_tagged,
    #   :total_tagged_you => total_tagged_you,
    #   :you_total_unique_places => you_total_unique_places,
    #   :you_friend_total_unique_places => you_friend_total_unique_places,
    #   :friend_tagged_you_array => friend_tagged_you_array,
    #   :you_tagged_friend_array => you_tagged_friend_array,
    #   :you_top_places_array => you_top_places_array,
    #   :you_friends_top_places_array => you_friends_top_places_array
    # }

    respond_to do |format|
      format.xml  { render :xml => response_array }
      format.json  { render :json => response_array }
    end

  end

  def friends
  end

  # /users/me/places
  # same as places/:place_id/me where it gets an index
  def places

    api_call_start = Time.now.to_f

    # We should limit results to 50 if no count is specified
    limit_count = 50
    if !params[:count].nil?
      limit_count =  params[:count].to_i
    end

    ##
    # Getting the friend's list of the place
    ##
    query = "select a.place_id, a.facebook_id, b.full_name, b.first_name
            from kupos a
            join users b on a.facebook_id = b.facebook_id
            join friends f on a.facebook_id = f.friend_id or a.facebook_id= #{@current_user.facebook_id}
            where f.facebook_id=#{@current_user.facebook_id}
            group by a.place_id, a.facebook_id
          "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    friend_list_of_place = {}
    place_id_friend_array = {}
    mysqlresults.each(:as => :hash) do |row|

      place_id_friend_array[row['place_id'].to_s+'_'+row['facebook_id'].to_s]=1

      if !friend_list_of_place.has_key?(row['place_id'].to_s)
        friend_list_of_place[row['place_id'].to_s] = []
        friend_hash = {
          :facebook_id => row['facebook_id'],
          :full_name => row['full_name'],
          :first_name => row['first_name']
        }
        friend_list_of_place[row['place_id'].to_s] << friend_hash
      else
        friend_hash = {
          :facebook_id => row['facebook_id'],
          :full_name => row['full_name'],
          :first_name => row['first_name']
        }
        friend_list_of_place[row['place_id'].to_s] << friend_hash
      end

    end

    ##
    # Getting tagged user places
    ##
    query = "select b.place_id, b.facebook_id, u.full_name, u.first_name
        from tagged_users b
        join friends f on b.facebook_id = f.friend_id or b.facebook_id= #{@current_user.facebook_id}
        join users u on u.facebook_id = b.facebook_id
        where f.facebook_id = #{@current_user.facebook_id}"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|

      if !place_id_friend_array.has_key?(row['place_id'].to_s+'_'+row['facebook_id'].to_s)
        place_id_friend_array[row['place_id'].to_s+'_'+row['facebook_id'].to_s]=1
        if !friend_list_of_place.has_key?(row['place_id'].to_s)
          friend_list_of_place[row['place_id'].to_s] = []
          friend_hash = {
            :facebook_id => row['facebook_id'],
            :full_name => row['full_name'],
            :first_name => row['first_name']
          }
          friend_list_of_place[row['place_id'].to_s] << friend_hash
        else
          friend_hash = {
            :facebook_id => row['facebook_id'],
            :full_name => row['full_name'],
            :first_name => row['first_name']
          }
          friend_list_of_place[row['place_id'].to_s] << friend_hash

        end
      end
    end

    ##
    # Getting the activity of the place
    ##
    query = "select place_id, count(*) as activity_count
            from kupos a
            where a.facebook_id in (select friend_id from friends where facebook_id=#{@current_user.facebook_id})
                or a.facebook_id=#{@current_user.facebook_id}
            group by 1
          "
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    activity_of_place = {}
    mysqlresults.each(:as => :hash) do |row|
      activity_of_place[row['place_id'].to_s] = row['activity_count']
    end

    ##
    # pass since, then get everything > since
    ##

    # convert the UTC unix timestamp to Ruby Date and them back to MySQL datetime (utc)
    # retarded lol
    if params[:since]!=nil && params[:until]==nil
      since_time = Time.at(params[:since].to_i).utc.to_s(:db)
      time_bounds = " and a.created_at > ('#{since_time}')"
      # pass until, then get everything < until
    elsif params[:since]==nil && params[:until]!=nil
      until_time = Time.at(params[:until].to_i).utc.to_s(:db)
      time_bounds = " and a.created_at < ('#{until_time}')"
    else
      time_bounds = ""
    end

    ##
    # Get the actual last kupo of a place to show on the home screen
    ##
    query = "
        select p.id as place_dbid, p.place_id, p.name as place_name, p.city, p.state, p.picture as place_picture_url,
              a.facebook_id, a.kupo_type, a.kupo_type, a.comment, a.has_photo, a.has_video, a.created_at, u.full_name
        from kupos a
        join (
          select place_id, max(in_k.id) as id
          from kupos in_k
          join friends f on in_k.facebook_id = f.friend_id or in_k.facebook_id= #{@current_user.facebook_id}
          where f.facebook_id=#{@current_user.facebook_id}
          group by place_id
        ) b on a.id = b.id
        join places p on p.place_id=b.place_id
        join users u on a.facebook_id = u.facebook_id
        where a.facebook_id = u.facebook_id " + time_bounds + "
        order by a.created_at desc
    "
    response_hash = {}
    response_array = []
    total_count=0
    last_time_hit = 0
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      total_count+=1
      if total_count<=limit_count
        row_hash = {
          :id => row['place_dbid'].to_s,
          :place_id => row['place_id'].to_s,
          :place_city => row['city'],
          :place_state => row['state'],
          :name => row['place_name'],
          :picture_url => row['place_picture_url'],
          :author_id => row['facebook_id'].to_s,
          :author_name => row['full_name'],
          :friend_list => friend_list_of_place[row['place_id'].to_s],
          :activity_count => activity_of_place[row['place_id'].to_s].to_i,
          :kupo_type => row['kupo_type'],
          :comment => row['comment'],
          :has_photo => row['has_photo'],
          :has_video => row['has_video'],
          :timestamp => row['created_at'].to_i
        }
        last_time_hit = row['created_at'].to_i
        response_array << row_hash
      else
      end
    end

    # Construct Response
    response_hash[:values] = response_array
    response_hash[:count] = response_array.length
    response_hash[:total] = total_count

    api_call_duration = Time.now.to_f - api_call_start

    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'home',nil,nil,api_call_duration,response_hash[:count],response_hash[:total])

    # temporary for debugging
    # LOGGING::Logging.logfunction(request,@current_user.facebook_id,'home',nil,nil,response_hash[:count],response_hash[:total],params[:until].to_i,last_time_hit)

    # for web user
    @response = response_hash

    respond_to do |format|
      format.html
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end

  end

  # Gets complete facebook friend's list
  # Also show joined_at date of user if they registered with Moogle
  # ':version/users/:user_id/friends'
  def friends

    # We should limit results to 50 if no count is specified
    limit_count = 50
    if !params[:count].nil?
      limit_count =  params[:count].to_i
    end

    api_call_start = Time.now.to_f

    query = "
      select b.facebook_id, b.full_name, b.first_name, a.joined_at,
            k.id, k.kupo_type, k.comment, k.place_id, k.checkin_id,
            p.name as place_name
            from friends a
            join users b on a.friend_id = b.facebook_id
            left join kupos k on c.id = b.last_kupo
            left join places p on p.place_id = c.place_id
      where a.facebook_id = #{@current_user.facebook_id}
      order by joined_at desc, b.first_name
    "

    response_array = []
    total_count=0
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      limit_count-=1
      total_count+=1
      if limit_count>=0
        row_hash = {
          :facebook_id => row['facebook_id'],
          :full_name => row['full_name'],
          :first_name => row['first_name'],
          :joined_at => row['joined_at']
        }
        response_array << row_hash
      end
    end

    response_hash[:values] = response_array
    response_hash[:count] = response_array.length
    response_hash[:total] = total_count

    api_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'friends',nil,nil,api_call_duration,nil,nil)

    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end

  end

  def kupos
  end

  def checkins
  end

  # Gets a list of events that the user is following
  def followed
    # Api call logging
    api_call_start = Time.now.to_f

    # We should limit results to 50 if no count is specified
    limit_count = 50
    if !params[:count].nil?
      limit_count =  params[:count].to_i
    end

    # mysql query
    # query to return events a user is participating in
    query = "
            select e.*
            from events e
            join events_users eu on eu.event_id = e.id
            where eu.user_id = #{@current_user.id}
            "

    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      row_hash = {
        :tag => row['tag'],
        :name => row['name'],
        :is_private => row['is_private'],
        :updated_at => row['updated_at']
      }
      response_array << row_hash
    end

    # Api call logging
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'followed',nil,nil,api_call_duration,nil,nil)

    response_hash = {}
    response_hash[:data] = response_array

    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end
  end

  # Gets a list of events that the user or the user's friends participated in
  def events
    # Api call logging
    api_call_start = Time.now.to_f

    # We should limit results to 50 if no count is specified
    limit_count = 50
    if !params[:count].nil?
      limit_count =  params[:count].to_i
    end
    
    # mysql query
    # query for events 1st degree friends are participating in
    # (exclude events user is already following)
    query = "
            select e.*
            from events e
            join events_users eu on eu.event_id = e.id
            join friendships f on eu.user_id = f.friend_id and f.user_id= #{@current_user.id}
            where eu.event_id not in
              ( select event_id
                from events_users
                where user_id =  #{@current_user.id}
                )
            group by e.id
            order by e.updated_at desc
    "
    
    response_array = []
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    mysqlresults.each(:as => :hash) do |row|
      row_hash = {
        :tag => row['tag'],
        :name => row['name'],
        :is_private => row['is_private'],
        :updated_at => row['updated_at']
      }
      response_array << row_hash
    end
    
    # Api call logging
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.id,'events',nil,nil,api_call_duration,nil,nil)

    response_hash = {}
    response_hash[:data] = response_array

    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end
  end

end
