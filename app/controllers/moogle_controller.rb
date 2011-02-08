class MoogleController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end
  
  # This API registers a new session from a client
  # Receives a POST with access_token from the user
  # This will start the API flow to grab user and friends checkins
  def session
    Rails.logger.info request.query_parameters.inspect
    
  end
  
  
end
