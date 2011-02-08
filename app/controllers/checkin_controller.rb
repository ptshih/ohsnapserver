class CheckinController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end

  def index
  end

  def show
  end

  def me
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

    responseArray = []

    Checkin.where("facebook_id = #{params[:facebook_id].to_i}").each do |checkin|
      responseHash = {
        :checkin_id => checkin['checkin_id'],
        :facebook_id => checkin['facebook_id'],
        :message => checkin['message'],
        :place_id => checkin['place_id'],
        :place_name => checkin.place['name'],
        :app_id => checkin['app_id'],
        :app_name => checkin.app['name'],
        :checkin_timestamp => Time.parse(checkin['created_time'].to_s).to_i
      }
      responseArray << responseHash
    end

    respond_to do |format|
      format.xml  { render :xml => responseArray }
      format.json  { render :json => responseArray }
    end
  end

  def friends
  end
end
