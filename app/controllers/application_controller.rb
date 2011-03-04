class ApplicationController < ActionController::Base
  # protect_from_forgery # disable this for local CURL requests
  
  def load_version(valid_versions = ["v1","v2","v3"])
    @version =  params[:version]
    render_status("Error:  Invalid Version") and return false unless valid_versions.include?(@version)
  end
  
  def load_facebook_api
    if params[:access_token].nil?
      params[:access_token] = "H_U8HT7bMvsDjEjb8oOjq4qWaY-S7MP8F5YQFNFzggQ.eyJpdiI6Ino1LXpBQ0pNRjJkNzM3YTdGRDhudXcifQ.h5zY_4HM_Ir3jg4mnyySYRvL26DxPgzg3NSI4Tcn_1bXn1Fqdgui1X7W6pDmJQagM5fXqCo7ie4EnCsi2t8OaMGVSTAZ-LSn9fuJFL-ucYj3Siz3bW17Dn6kMDcwxA3fghX9tUgzK0Vtnli6Sn1afA"
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
  
end
