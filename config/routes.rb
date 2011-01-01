Worlize::Application.routes.draw do |map|

  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'

  root :to => "welcome#index"
  
  match '/press(/:action)', { :controller => :press, :as => :press }
  
  match '/about' => 'welcome#about', :as => :about

  resources :registrations
  
  resource :dashboard, :controller => :dashboard do
    resources :authentications
  end

  namespace "marketplace" do
    resources :backgrounds do
      member do
        post :buy
        get :buy
        put :test
      end
    end
  end
  
  namespace "locker" do
    resources :backgrounds
    resources :avatars
    resources :in_world_objects
  end

  resources :friends do
    member do
      post :request_friendship
      post :accept_friendship
      post :reject_friendship
      post :retract_friendship_request
      post :invite_to_join
      post :request_to_join
      post :grant_permission_to_join
    end
  end

  resources :users do
    collection do
      get :search
    end
    resources :friends
  end
  
  resource :preferences
  
  resources :gifts do
    member do
      post 'accept_gift'
    end
  end
  
  resources :avatars do
    member do
      post 'send_as_gift'
    end
  end
  
  resources :invite, :controller => 'Invitations'
  
  match 'admin' => 'admin#index', :as => :admin_index
  
  namespace "admin" do
    resources :authentications
    resources :beta_registrations do
      member do
        post 'invite_user'
      end
    end
    
    resources :users
    resources :worlds do
      resources :rooms
    end
    
    resource :management, :controller => 'management' do
      member do
        post 'broadcast_message'
      end
    end
    
    resource :status, :controller => 'status' do
    end
  end
  
  resources :worlds do
    resources :rooms
    member do
      get :user_list
    end
  end
  
  resources :rooms do
    resources :hotspots, :controller => 'in_world/hotspots'
    resources :objects, :controller => 'in_world/objects'
    resources :youtube_players, :controller => 'in_world/youtube_players'
    member do
      post :enter
      get :enter, :as => :enter_room
      post :set_background
    end
  end

  resource :user_session
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  match 'signup' => 'users#new', :as => :signup

  match 'enter', :to => "welcome#enter", :as => :enter_world
  

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
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
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
  #       get :recent, :on => :collection
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
