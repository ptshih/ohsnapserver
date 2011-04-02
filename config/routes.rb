Moogle::Application.routes.draw do
  
  # Routes will always pass a version (v1)
  #
  # !!! NOTE !!!
  # I commented out all the endpoints that are not currently in use
  #
  # I split up all our API ENDPOINTS into two categories, one is USER oriented, one is NON-USER (GLOBAL) oriented
  # This is sorta how the FB graph api and foursquare venues api works
  
  ###
  # User Specific Endpoints
  ###
  
  # Passing "me" as :user_id will default to current user
  
  # General
  # match ':version/users', :controller => 'user', :action => 'index', :via => :get # LIST: get all users in the database
  # match ':version/users/:user_id', :controller => 'user', :action => 'show', :via => :get # SINGLE: Single User with ID
  # match ':version/users/search', :controller => 'user', :action => 'search', :via => :get # LIST: get all users in the database
  # Actions
  match ':version/users/register', :controller => 'user', :action => 'register', :via => :post # CREATE: Register new user with access_token
  match ':version/users/session', :controller => 'user', :action => 'session', :via => :post # SESSION: Start a new session for the current user
  # Connections
  match ':version/users/:user_id/profile', :controller => 'user', :action => 'profile', :via => :get # SINGLE: Me/Profile details for user with ID
  match ':version/users/:user_id/places', :controller => 'user', :action => 'places', :via => :get # LIST: get all places a user participated at
  # Connections that are Resources
  # match ':version/users/:user_id/friends', :controller => 'user', :action => 'friends', :via => :get # LIST: get all friends for a user (param for degree: 1 or 2)
  # match ':version/users/:user_id/kupos', :controller => 'user', :action => 'kupos', :via => :get # LIST: get all kupos the user has created
  # match ':version/users/:user_id/checkins', :controller => 'user', :action => 'checkins', :via => :get # LIST: get all checkins the user is part of
  
  ###
  # Non-User Specific Endpoints
  ###
  
  # Places
  # General
  match ':version/places', :controller => 'place', :action => 'index', :via => :get # LIST: get all places in the database, optional param to filter by @current_user
  match ':version/places/:place_id', :controller => 'place', :action => 'show', :via => :get # SINGLE: get detail for place with ID
  # match ':version/places/search', :controller => 'place', :action => 'search', :via => :get # LIST: search for a place with query
  match ':version/places/nearby', :controller => 'place', :action => 'nearby', :via => :get # LIST: get all places nearby location (lat,lng)
  match ':version/places/popular', :controller => 'place', :action => 'popular', :via => :get # LIST: get all popular nearby location (lat,lng), optional param for filter by user's social network
  # Connections
  match ':version/places/:place_id/kupos', :controller => 'place', :action => 'kupos', :via => :get # LIST: get all kupos for a single place with ID, param allows filter by @current_user
  match ':version/places/:place_id/photos', :controller => 'place', :action => 'photos', :via => :get # LIST: get all photos associated with a kupo for a single place with ID
  # match ':version/places/:place_id/reviews', :controller => 'place', :action => 'reviews', :via => :get # LIST: get all reviews for a single place with ID
  # match ':version/places/:place_id/wall', :controller => 'place', :action => 'wall', :via => :get # LIST: get all wall posts for a single place with ID
  # match ':version/places/:place_id/page', :controller => 'place', :action => 'page', :via => :get # SINGLE: get page detail for place

  # Kupos
  # match ':version/kupos', :controller => 'kupo', :action =>'index', :via => :get # LIST: get all kupos in the database
  # match ':version/kupos/:kupo_id', :controller => 'kupo', :action =>'show', :via => :get # SINGLE: get detail for kupo with ID
  # match ':version/kupos/search', :controller => 'kupo', :action => 'search', :via => :get # LIST: search for a kupo with query
  # Actions
  match ':version/kupos/new', :controller => 'kupo', :action =>'new', :via => :post # CREATE: create a new kupo
  
  # Checkins
  # match ':version/checkins', :controller => 'checkin', :action => 'index', :via => :get # LIST: get all checkins in the database
  # match ':version/checkins/:checkin_id', :controller => 'checkin', :action => 'show', :via => :get # SINGLE: get details for a single checkin
  # match ':version/checkins/search', :controller => 'checkin', :action => 'search', :via => :get # LIST: search for a checkin with query
  # Connections
  # match ':version/checkins/:checkin_id/place', :controller => 'checkin', :action => 'place', :via => :get # SINGLE: get place associated with this checkin
  # match ':version/checkins/:checkin_id/comments', :controller => 'checkin', :action => 'comments', :via => :get # LIST: get comments for a single checkin
  # match ':version/checkins/:checkin_id/likes', :controller => 'checkin', :action => 'likes', :via => :get # LIST: get likes for a single checkin
  # Actions
  match ':version/checkins/new', :controller => 'checkin', :action =>'new', :via => :post # CREATE: create a new checkin
  
  # Moogle
  match 'moogle/fbcallback', :controller => 'moogle', :action => 'fbcallback'

end
