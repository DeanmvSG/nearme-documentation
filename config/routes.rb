DesksnearMe::Application.routes.draw do

  if defined? MailView
    mount ReservationMailerPreview => 'mail_view/reservations'
    mount UserMailerPreview => 'mail_view/users'
    mount PostActionMailerPreview => 'mail_view/post_action'
    mount InquiryMailerPreview => 'mail_view/inquiries'
    mount ListingMailerPreview => 'mail_view/listings'
    mount RatingMailerPreview => 'mail_view/ratings'
    mount ListingMessageMailerPreview => 'mail_view/listing_messages'
    mount ReengagementMailerPreview => 'mail_view/reengagement'
    mount RecurringMailerPreview => 'mail_view/recurring'
  end

  match '/404', :to => 'errors#not_found'
  match '/422', :to => 'errors#server_error'
  match '/500', :to => 'errors#server_error'
  match '/domain-not-configured', :to => 'errors#domain_not_configured', :as => 'domain_not_configured'

  namespace :admin do
    match '/', :to => "dashboard#show"
    resources :users do
      member do
        post :login_as
      end

      collection do
        post :restore_session
      end
    end

    resources :reservations
    resources :companies
    resources :payment_transfers do
      member do
        post :transferred
      end

      collection do
        post :generate
      end
    end

    resources :instances do
      resources :partners
    end
    resources :pages
  end

  namespace :instance_admin do
    match '/', :to => "base#index"
    resources :analytics, :only => [:index]
    resources :inventories, :only => [:index, :show] do
      post :login_as, on: :member
      post :restore_session, on: :collection
    end

    resources :partners
    resource :settings, :only => [:show, :update], :controller => 'settings'
    namespace :settings do
      resources :location_types, only: [:index, :create, :destroy_modal, :destroy] do
        get 'destroy_modal', on: :member
      end
      resources :listing_types, only: [:index, :create, :destroy_modal, :destroy] do
        get 'destroy_modal', on: :member
      end
    end
    resource :theme, :only => [:show, :update], :controller => 'theme'
    resources :transfers do
      member do
        post :transferred
      end

      collection do
        post :generate
      end
    end
    resources :users, :only => [:index, :create]
    resources :pages

    namespace :users do
      resources :instance_admins, :only => [:create, :update, :destroy, :index]
      resources :instance_admin_roles, :only => [:create, :update, :destroy, :index]
    end
  end

  resources :locations, :only => [:show] do
    resources :listings, :controller => 'locations/listings' do
      member do
        get :ask_a_question
      end
    end

    resource :social_share, :only => [:new], :controller => 'locations/social_share'

    collection do
      get :populate_address_components_form
      post :populate_address_components
    end
  end

  resources :listings, :only => [:index, :show] do
    resources :reservations, :only => [:create, :update], :controller => "listings/reservations" do
      collection do
        post :review
        post :store_reservation_request
      end
      member do
        get :booking_successful
      end
      get :hourly_availability_schedule, :on => :collection
    end

    resources :listing_messages, :controller => "listings/listing_messages" do
      put :archive
    end
  end

  resources :listing_messages, only: [:index] do 
    collection do 
      get :archived
    end
  end

  resources :reservations, :only => [] do
    resources :guest_ratings, :only => [:new, :create]
    resources :host_ratings, :only => [:new, :create]
  end
  match '/reservations/:id/guest_rating' => 'dashboard#guest_rating', as: 'guest_rating'
  match '/reservations/:id/host_rating' => 'reservations#host_rating', as: 'host_rating'

  match '/auth/:provider/callback' => 'authentications#create'
  match "/auth/failure", to: "authentications#failure"
  devise_for :users, :controllers => { :registrations => 'registrations', :sessions => 'sessions', :passwords => 'passwords' }
  devise_scope :user do
    post "users/avatar", :to => "registrations#avatar", :as => "avatar"
    get "users/edit_avatar", :to => "registrations#edit_avatar", :as => "edit_avatar"
    put "users/update_avatar", :to => "registrations#update_avatar", :as => "update_avatar"
    get "users/set_password", :to => "registrations#set_password", :as => "set_password"
    put "users/update_password", :to => "registrations#update_password", :as => "update_password"
    post "users/store_google_analytics_id", :to => "registrations#store_google_analytics_id", :as => "store_google_analytics"
    post "users/store_geolocated_location", :to => "registrations#store_geolocated_location", :as => "store_geolocated_location"
    get "users/", :to => "registrations#new"
    get "users/verify/:id/:token", :to => "registrations#verify", :as => "verify_user"
    delete "users/avatar", :to => "registrations#destroy_avatar", :as => "destroy_avatar"
    get "users/:id", :to => "registrations#show", :as => "profile"
    get "users/unsubscribe/:signature", :to => "registrations#unsubscribe", :as => "unsubscribe"

    put "users/store_correct_ip", :to => "sessions#store_correct_ip", :as => "store_correct_ip"

    get "/instance_admin/sessions/new", :to => "instance_admin::sessions#new", :as => 'instance_admin_login'
  end

  resources :reservations, :except => [:update, :destroy, :show] do
    member do
      post :user_cancel
      get :export
      get :booking_successful
    end
    collection do
      get :upcoming
      get :archived
    end
  end

  resource :dashboard, :only => [:show], :controller => 'dashboard' do
    member do
      get :bookings, :to => 'reservations#upcoming'
      get :analytics
      get :listings
      get :manage_guests
      get :transfers
    end
  end

  namespace :manage do

    resources :companies, :only => [:edit, :update, :show]

    resources :white_labels, :only => [:edit, :update, :show]

    resources :users, :except => [:edit, :update]
    resources :themes, :only => [] do
      member do
        delete :destroy_image
      end
    end

    resources :locations do
      resources :listings do
        member do
          get :enable
          get :disable
        end
      end
    end

    resources :photos, :only => [:create, :destroy, :edit, :update]

    resources :listings do
      resources :reservations, :controller => 'listings/reservations' do
        member do
          post :confirm
          get :confirm
          put :reject
          get :rejection_form
          post :host_cancel
        end
      end
    end
  end

  match "/search", :to => "search#index", :as => :search
  match "/search/show/:id", :to => "search#show"

  resources :search_notifications, only: [:create]

  resource :event_tracker, only: [:create], :controller => 'event_tracker'

  resources :authentications, :only => [:create, :destroy] do
    collection do
      post :clear # Clear authentications stored in session
    end
  end

  scope '/space' do
    get '/new' => 'space_wizard#new', :as => "new_space_wizard"
    get "/list" => "space_wizard#list", :as => "space_wizard_list"
    post "/list" => "space_wizard#submit_listing"
    put "/list" => "space_wizard#submit_listing"
    post "/photo" => "space_wizard#submit_photo", :as => "space_wizard_photo"
    put "/photo" => "space_wizard#submit_photo", :as => "space_wizard_photo"
    delete "/photo/:id" => "space_wizard#destroy_photo", :as => "destroy_space_wizard_photo"
  end

  root :to => "public#index"

  namespace :v1, :defaults => { :format => 'json' } do

    resource :authentication, only: [:create]
    post 'authentication/:provider', :to => 'authentications#social'

    resource :registration, only: [:create]

    get  'profile',  :to => 'profile#show'
    put  'profile',  :to => 'profile#update'
    post 'profile/avatar/:filename', :to => 'profile#upload_avatar'
    delete 'profile/avatar', :to => 'profile#destroy_avatar'

    get  'iplookup',  :to => 'iplookup#index'

    resources :guest_ratings, :only => [:create]
    resources :host_ratings, :only => [:create]

    resources :locations do
      collection do
        get 'list'
      end
    end

    resources :photos

    resources :listings, :only => [:show,:create, :update, :destroy] do
      member do
        post 'reservation'
        post 'availability'
        post 'inquiry'
        post 'share'
        get  'patrons'
        get  'connections'
      end
      collection do
        post 'search'
        post 'query'
      end
      resource :rating, only: [:show, :update, :destroy]
    end

    resources :reservations do
      collection do
        get 'past'
        get 'future'
      end
    end

    resource :social, only: [:show], controller: 'social' do
      # Hmm, can this be better?
      resource :facebook, only: [:show, :update, :destroy],
        controller: 'social_provider', provider: 'facebook'
      resource :twitter,  only: [:show, :update, :destroy],
        controller: 'social_provider', provider: 'twitter'
      resource :linkedin, only: [:show, :update, :destroy],
        controller: 'social_provider', provider: 'linkedin'
    end

    get 'amenities', to: 'amenities#index'
    get 'organizations', to: 'organizations#index'
  end

  match "/pages/:path", to: 'pages#show', as: :pages
  match "/w-hotels-desks-near-me", to: 'locations#w_hotels', as: :w_hotels_location
  match "/W-hotels-desks-near-me", to: 'locations#w_hotels'
  match "/careers", to: 'pages#careers'
  match "/rent-accounting-desks", to: 'locations#vertical_accounting'
  match "/rent-legal-desks", to: 'locations#vertical_law'
  match "/rent-hairdressing-booth-stations", to: redirect(subdomain: 'rent-salon-space', path: '/')
  match "/rent-design-desks", to: 'locations#vertical_design'
end
