Moogle::Application.routes.draw do
  
  # Routes will always pass a version (v1)
  # All routes expect a parameter: access_token
  # All routes assume @current_user except for login#register
  
  ###
  # Login Endpoints
  ###
  
  # scope :protocol => 'https://', :constraints => { :protocol => 'https://' } do
  #   match 'mash/token/:id' => 'mash#token', :via => :post, :constraints => { :protocol => 'https' }
  # end
  
  # Test APIs
  match ':version/albums_test', :to => 'album#test', :via => :get # Auth Not Requred
  match ':version/snaps_test', :to => 'snap#test', :via => :get # Auth Not Requred
  
  # 
  # Actions
  match ':version/login/register', :to => 'login#register', :via => :post # CREATE: Register new user with access_token
  match ':version/login/session', :to => 'login#session', :via => :post # SESSION: Start a new session for the current user
  
  ###
  # Album
  ###
  match ':version/albums', :to => 'album#index', :via => :get # Auth Required
  match ':version/albums', :to => 'album#create', :via => :post # Auth Required
  # match ':version/albums/:album_id', :to => 'album#destroy', :via => [:post, :delete]
  # match ':version/albums/:album_id/edit', :to => 'album#edit', :via => :post
  
  ###
  # Snaps
  ###
  match ':version/snaps', :to => 'snap#index', :via => :get # Auth Optional, parameter :album_id required
  match ':version/snaps', :to => 'snap#create', :via => :post # Auth Required
  match ':version/snaps/:snap_id', :to => 'snap#destroy', :via => :delete # Auth Required
  match ':version/snaps/comment/:snap_id', :to => 'snap#comment', :via => :post # Auth Required
  match ':version/snaps/like/:snap_id', :to => 'snap#like', :via => :post # Auth Required
  
  ###
  # Friendships
  ###
  match ':version/friendships', :controller => 'friendship', :action => 'index', :via => :get
  match ':version/friendships', :controller => 'friendship', :action => 'create', :via => :post

end
