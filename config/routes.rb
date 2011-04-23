Moogle::Application.routes.draw do
  
  # Routes will always pass a version (v1)
  #
  # !!! NOTE !!!
  # I commented out all the endpoints that are not currently in use
  #
  # I split up all our API ENDPOINTS into two categories, one is USER oriented, one is NON-USER (GLOBAL) oriented
  # This is sorta how the FB graph api and foursquare venues api works
  
  ###
  # Login Endpoints
  ###
  
  # Actions
  match ':version/login/register', :controller => 'login', :action => 'register', :via => :post # CREATE: Register new user with access_token
  match ':version/login/session', :controller => 'login', :action => 'session', :via => :post # SESSION: Start a new session for the current user
  
  ###
  # Album
  ###
  match ':version/albums', :controller => 'album', :action => 'index', :via => :get # LIST: get all albums for a user (authenticated user)
  match ':version/albums/new', :controller => 'album', :action =>'new', :via => :post # CREATE: create a new album
  match ':version/albums/:album_id/snaps', :controller => 'album', :action => 'snaps', :via => :get # LIST: get all snaps for an album (public)
  match ':version/albums/:album_id/newsnap', :controller => 'album', :action => 'newsnap', :via => :post # CREATE: create a new snap for current album

end
