class ApplicationController < ActionController::Base
  # protect_from_forgery # disable this for local CURL requests
  
  def load_version(valid_versions = ["v1","v2","v3"])
    @version =  params[:version]
    render_status("Error:  Invalid Version") and return false unless valid_versions.include?(@version)
  end
  
  def load_facebook_api
    if params[:access_token].nil?
      # params[:access_token] = "132514440148709|22ebfa70b9a561d421c076fe-100002025298734|dJd8XJJg4p67Jh_lRFkkgEHX4Go"
      # params[:access_token] = "132514440148709|ddfc7b74179c6fd2f6e081ff-4804606|9SUyWXArEX9LFCAuY3DoFDvhgl0"
      params[:access_token] = "dW73Evxj1pOcaOkGXF-8rhYg-fIv_-9h1dZqOFHsmwM.eyJpdiI6Ik0yVGN1VXdMSWFoTlgtZ2JtWC1qMGcifQ.UCmt1pNhjgCQ_f-W3R-n7pdl6wuA8aaN2JmfnyD_r9wRN6JAB2CjFJfGLmfkPW8IgSiY2QMNC5GdsSv98FzIYmRhT2hs-psInPaSAPNCXS9OI_k2ILoE6fXeH-Jk0eV9" # jessa
    end
    @facebook_api = API::FacebookApi.new(params[:access_token])
  end
  
  # Reads the fb access_token param from requests and stores the current user object
  def authenticate_token
    self.load_facebook_api
    
    puts "\nauthenticating token\n"
    if not params[:access_token].nil?
      @current_user = User.find_by_access_token(params[:access_token])
      if @current_user.nil?
        puts "cant find user"
        self.create_new_user
      end
    else
      puts "\nnil access_token\n"
      @current_user = nil
    end
  end
  
  def create_new_user
    # create a new user given access token
    # Ask facebook for this current user's information via API
    @current_user = @facebook_api.find_user_for_facebook_access_token
  end
  
  def default_geocoordinates
    # latitude +37.401955, longitude -121.922429
    if params[:lat].nil?
      params[:lat] = 37.401955
    end
    if params[:lng].nil?
      params[:lng] = -121.922429
    end
    # in miles
    # if params[:distance].nil?
    #       params[:distance] = 1
    #     end
  end
  
end
