Worlize::Application.routes.draw do |map|

  get "client_errors/create"

  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'

  root :to => "welcome#index"
  
  match '/press/release' => redirect('/press')
  
  match '/press(/:action)', { :controller => :press, :as => :press }
  
  match '/developers' => redirect('/developer')
  match '/developer' => 'developers#index', :as => :developer
  
  match '/about' => 'welcome#about', :as => :about
  match '/email_thank_you' => 'welcome#email_thank_you', :as => :email_thank_you

  match '/registrations/new' => redirect('/users/new')
  
  match '/paypal/ipn' => 'paypal#ipn', :via => :post
  match '/paypal/return' => 'paypal#return', :via => :get, :as => :paypal_return
  
  match '/aviary/edit_complete' => 'aviary#edit_complete', :via => :post, :as => :aviary_edit_complete
  
  match '/fb-canvas' => 'facebook_canvas#index', :via => :post
  match '/fb-canvas/ignore_request/:id' => 'facebook_canvas#ignore_request', :via => :post
  match '/fb-canvas/handle_request/:id' => 'facebook_canvas#handle_request', :via => :post
  match '/fb-canvas/auth_callback' => 'facebook_canvas#auth_callback', :via => :get
  match '/fb-canvas/enter_worlize' => 'facebook_canvas#enter_worlize', :via => :get
  match '/fb-canvas/link_account' => 'facebook_canvas#link_account', :via => :post
  
  match '/embed/badge' => 'embed#render_badge', :via => :get
  
  match '/dialogs/check_for_dialogs' => 'dialogs#check_for_dialogs', :via => :get
  match '/dialogs/css' => 'dialogs#css', :via => :get
  
  resources :authentications do
    collection do
      post :connect_facebook_via_js
    end
  end
  
  resources :client_errors, :only => :create
  
  resource :dashboard, :controller => :dashboard

  match "/marketplace" => 'marketplace/categories#index'
  match "/marketplace/search" => 'marketplace/items#search'
  namespace "marketplace" do
    resources :themes, :only => :show
    resources :categories do
      resources :items, :only => :index
      
      resources :avatars, :only => :index,
                          :controller => 'items',
                          :defaults => { :item_type => 'Avatar' }

      resources :backgrounds, :only => :index,
                              :controller => 'items',
                              :defaults => { :item_type => 'Background' }
                          
      resources :objects, :only => :index,
                          :controller => 'items',
                          :defaults => { :item_type => 'InWorldObject' }
                          
      resources :props, :only => :index,
                        :controller => 'items',
                        :defaults => { :item_type => 'Prop' }
    end
    resources :items do
      member do
        post :buy
      end
    end
  end
  
  namespace "locker" do
    resources :backgrounds
    resources :avatars
    resources :in_world_objects
    resource :slots do
      member do
        get :prices
        post :buy
      end
    end
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
    collection do
      post :sync_facebook_friends
    end
  end

  resources :users do
    member do
      get :join
    end
    collection do
      get :search
      get :validate_field
    end
    resources :friends
  end
  
  resource :preferences
  
  resources :gifts do
    member do
      post 'accept'
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
    resources :client_errors
    resources :authentications
    resources :beta_registrations do
      collection do
        post 'invite_all_users'
      end
      member do
        post 'invite_user'
      end
    end
    
    resources :users do
      member do
        post 'give_currency'
        post 'login_as_user'
        post 'set_as_global_moderator'
        post 'unset_as_global_moderator'
        post 'set_world_as_initial_template_world'
        post 'add_to_public_worlds'
        post 'remove_from_public_worlds'
        post 'reactivate'
      end
    end
    
    resources :rooms do
      member do
        post 'set_as_gate_room'
      end
    end
    
    resources :worlds do
      resources :rooms
    end
    
    resources :promo_programs do
      member do
        post 'upload_image_asset'
        delete 'destroy_image_asset'
      end
    end
    
    resource :management, :controller => 'management' do
      member do
        post 'broadcast_message'
      end
    end
    
    resource :status, :controller => 'status' do
    end
    
    namespace "marketplace" do
      resources :licenses
      resources :categories do
        member do
          post 'update_subcategory_positions'
          post 'update_featured_item_positions'
          post 'update_carousel_item_positions'
        end
        resources :items, :except => [:edit]
      end
      resources :item_giveaways
      resources :tag_contexts
      resources :items do
        collection do
          post 'multiupload'
        end
        resources :featured_items
      end
      resources :featured_items
      resources :creators, :only => [:show, :create, :update, :destroy] do
        collection do
          get 'search'
        end
      end
      resources :themes
    end
    
    resources :virtual_currency_products do
      member do
        post 'archive'
        post 'move_higher'
        post 'move_lower'
      end
    end
  end
  
  resources :worlds do
    resources :rooms
    member do
      get :user_list
    end
  end
  
  resources :public_worlds
  
  resources :rooms do
    resources :hotspots, :controller => 'in_world/hotspots'
    resources :objects, :controller => 'in_world/objects'
    resources :youtube_players, :controller => 'in_world/youtube_players'
    collection do
      get :directory
    end
    member do
      post :enter
      get :enter, :as => :enter_room
      post :set_background
    end
  end

  resources :virtual_currency_products do
  end

  resource :user_session do
    member do
      get :vanilla_sso
    end
  end
    
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  match 'signup' => 'users#new', :as => :signup

  match 'enter', :to => "welcome#enter", :as => :enter_world
  

  match '/:link_code', :to => "sharing_link#show"

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
