RailsBootstrap::Application.routes.draw do

  devise_for :admin_users,{
    :path => :admin,
    :path_names => { :sign_in => 'login', :sign_out => "logout" }
  }

  devise_for :users

  
  namespace :admin do
    mount Sidekiq::Web => '/sidekiq'

    resources :news_feeds do
      get :process_entries, :on => :member
      post :load_entries, :on => :member
      get :search, :on => :collection

      resources :feed_entries do
        member do
          put   :toggle_visible
          post  :fetch_content
          post  :process_entry
          get   :re_index
          post   :update_coefficient
        end

        get :review_locations, :on => :collection
      end
    end

    resources :feed_entries, :only => :index do
      resources :tags, :only => :index do
        put :delete, :on => :collection
      end

      put   :set_primary_location

      collection do
        get :search
        get :review_locations
      end
    end

    resources :trends, only: :index do
      post "blacklist", on: :member, as: :blacklist
    end

    get 'social' => 'social_network_configurations#index'
    resources :social_network_configurations, only: :update

    resources :admin_users
    root :to => "news_feeds#index"
  end

  namespace :api do
    resources :tags, :only => :index
  end
  match 'signup' => "users#create"
  match 'home' => "home#index"
  match 'product' => "product#show"
  match 'mobile' => "home#mobile"
  match 'news/:id' => 'news#show', :as => :news

  resources :search, only: [:index]
  
  match 'api/paypal', :to => 'api/paypal#create', :via => %w(post)
  
  root :to => "home#index"

end
