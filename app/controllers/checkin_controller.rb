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
    if params[:people].nil?
      filter_people = "me"
    else
      filter_people = params[:people]
    end
    
    if filter_people == "me"
      query = "facebook_id = #{@current_user.facebook_id}"
    elsif filter_people == "friends"
      # Get an array of friend_ids
      facebook_id_array = Friend.select('friend_id').where("facebook_id = #{@current_user.facebook_id}").map {|f| f.friend_id}
      
      people_list = facebook_id_array.join(",")
      query = "facebook_id IN (#{people_list})"
    end
    
    # Distance filter
    # Category filter

    response_array = []

    Checkin.where(query).each do |checkin|
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
        :name => checkin.user['full_name'],
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
    response = @facebook_api.find_places_near_location(params[:lat], params[:lng], params[:distance], nil)
    
    # temporarily just bypass proxy FB's response
     
    respond_to do |format|
      format.xml  { render :xml => response['data'] }
      format.json  { render :json => response['data'] }
    end
  end
  
end
