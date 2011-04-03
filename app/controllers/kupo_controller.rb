class KupoController < ApplicationController
  before_filter :default_geocoordinates
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  ###
  ### Convenience Methods
  ###
  
  ###
  ### API Endpoints
  ###
  
  def index
  end
  
  def show
  end
  
  def search
  end
  
  def new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    api_call_start = Time.now.to_f
    k = Kupo.create(
      :facebook_id => @current_user.facebook_id,
      :kupo_type => params[:kupo_type],
      :place_id => params[:place_id],
      :comment => params[:comment],
      :photo => params[:image],
      :created_at => Time.now
    )
    api_call_duration = Time.now.to_f - api_call_start
    LOGGING::Logging.logfunction(request,@current_user.facebook_id,'addkupos',nil,nil,api_call_duration,k.id,k.kupo_type,k.place_id)
    response = {:success => "true"}
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end
