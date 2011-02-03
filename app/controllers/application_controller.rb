class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def load_version(valid_versions = ["v1","v2","v3"])
    @version =  params[:version]
    render_status("Error:  Invalid Version") and return false unless valid_versions.include?(@version)
  end
  
end
