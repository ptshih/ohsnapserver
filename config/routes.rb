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
  
  # 
  # Actions
  match ':version/login/register', :to => 'login#register', :via => :post # CREATE: Register new user with access_token
  match ':version/login/session', :to => 'login#session', :via => :post # SESSION: Start a new session for the current user
  
  ###
  # Album
  ###
  match ':version/albums', :to => 'album#index', :via => :get
  match ':version/albums/new', :to => 'album#create', :via => :post
  match ':version/albums/destroy/:album_id', :to => 'album#destroy', :via => [:post, :delete]
  match ':version/albums/:album_id/snaps', :to => 'album#snaps', :via => :get
  
  ###
  # Snaps
  ###
  match ':version/snaps/new', :to => 'snap#create', :via => :post
  match ':version/snaps/destroy/:snap_id', :to => 'snap#destroy', :via => [:post, :delete]

  match ':version/snaps/comment/:snap_id', :to => 'snap#comment', :via => :post
  match ':version/snaps/like/:snap_id', :to => 'snap#like', :via => :post
  
  ###
  # Friendships
  ###
  match ':version/friendships', :controller => 'friendship', :action => 'index', :via => :get
  match ':version/friendships', :controller => 'friendship', :action => 'create', :via => :post

end
