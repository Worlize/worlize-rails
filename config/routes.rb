Worlize::Application.routes.draw do |map|

  match '/auth/:provider/callback' => 'authentications#create'

  resources :authentications

  resources :registrations

  root :to => "welcome#index"

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
  end

  resources :users
  
  resource :preferences
  
  resources :avatars
  
  match 'admin' => 'admin#index', :as => :admin_index
  
  namespace "admin" do
    resources :beta_registrations do
      member do
        get 'build_account'
      end
    end
    resources :users
    resources :backgrounds
    resources :worlds do
      resources :rooms do
        member do
          post :enter
        end
      end
    end
  end
  
  resources :worlds do
    resources :rooms do
      
    end
  end
  
  resources :rooms do
    resources :hotspots, :controller => 'in_world/hotspots'
    resources :objects, :controller => 'in_world/objects'
    member do
      post :enter
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
