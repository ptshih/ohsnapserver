Moogle::Application.routes.draw do
  
  # Routes will always pass a version
  # Example: http://api.moogle.com/v1/user/54685403
  
  # Moogle Routes
  match ':version/moogle/session/:id', :controller => 'moogle', :action => 'session', :via => :post # List of Users
  
  # User Routes
  match ':version/user', :controller => 'user', :action => 'index', :via => :get # List of Users
  match ':version/user/:id', :controller => 'user', :action => 'show', :via => :get # Single User with ID
  
  # Checkin Routes
  match ':version/checkin', :controller => 'checkin', :action => 'index', :via => :get # List of Checkins
  match ':version/checkin/:id', :controller => 'checkin', :action => 'show', :via => :get # Single Checkin with ID
  match ':version/checkin/me/:facebook_id', :controller => 'checkin', :action => 'me', :via => :get # Checkins from user_id
  match ':version/checkin/friends/:facebook_id', :controller => 'checkin', :action => 'friends', :via => :get # Checkins from friends of user_id
  
  match ':version/checkin/nearby', :controller => 'checkin', :action => 'nearby', :via => :post # get nearby facebook places
  
  # Place routes
  match ':version/place', :controller => 'place', :action => 'index', :via => :get # List of Places
  match ':version/place/:id', :controller => 'place', :action => 'show', :via => :get # Single Place with ID
  match ':version/place/me/:user_id', :controller => 'place', :action => 'me', :via => :get # Places that user_id have been to
  match ':version/place/friends/:user_id', :controller => 'place', :action => 'friends', :via => :get # Places friends of user_id have been to
  
  # Mobile Server Examples  
  # map.connect ':version/messages/count', :controller => 'messages', :action => 'count', :conditions => { :method => :get }
    
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
