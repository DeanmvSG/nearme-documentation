DesksnearMe::Application.routes.draw do

  if Rails.env.development?
    mount ReservationMailer::Preview => 'mail_view/reservations'
    mount InquiryMailer::Preview => 'mail_view/inquiries'
    mount ListingMailer::Preview => 'mail_view/listings'
  end

  resources :companies
  resources :locations, :only => [:show] do
    resources :listings, :controller => 'locations/listings'
    resources :reservations, :controller => 'locations/reservations', :only => [:create] do
      post :review, :on => :collection
    end

    member do
      get :host
      get :networking
      get :availability_summary
    end

    collection do
      get :populate_address_components_form
      post :populate_address_components
    end
  end

  resources :listings, :only => [:index, :show] do
    resources :reservations, :only => [:new, :create, :update], :controller => "listings/reservations" do
      post :confirm
      post :reject
    end
  end

  match '/auth/:provider/callback' => 'authentications#create'
  match "/auth/failure", to: "authentications#failure"
  devise_for :users, :controllers => { :registrations => 'registrations', :sessions => 'sessions', :passwords => 'passwords' }

  resources :reservations, :only => :update

  ## routing after 'controlpanel/' is handled in backbone cf. router.js
  get 'controlpanel' => 'controlpanel#index', as: :controlpanel
  get 'controlpanel/locations' => 'controlpanel#index', as: :controlpanel

  resource :dashboard, :only => [:show], :controller => 'dashboard' do
    member do
      get :bookings
      get :listings
      get :reservations
    end
  end

  namespace :manage, :path => 'dashboard' do
    resources :companies do
      resources :locations, :only => [:index] do
      end
    end

    resources :locations do
      resources :listings, :only => [:index, :new, :create]
      member do
        get :map
        get :amenities
        get :availability
        get :photos
        get :associations
      end
    end

    resources :listings do
      resources :photos
    end
  end

  match "/search", :to => "search#index", :as => :search

  resources :authentications do
    collection do
      post :clear # Clear authentications stored in session
    end
  end

  scope '/space' do
    get '/new' => 'space_wizard#new', :as => "new_space_wizard"
    get '/complete' => "space_wizard#complete", :as => "space_wizard_complete"

    %w(company space desks).each do |step|
      get "/#{step}" => "space_wizard##{step}", :as => "space_wizard_#{step}"
      post "/#{step}" => "space_wizard#submit_#{step}"
      put "/#{step}" => "space_wizard#submit_#{step}"
    end
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

    resources :locations do
      collection do
        get 'list'
      end
    end

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

  match "/privacy", to: 'pages#privacy'
  match "/host-sign-up", to: 'pages#host_signup_1'
  match "/host-sign-up-2", to: 'pages#host_signup_2'
  match "/host-sign-up-3", to: 'pages#host_signup_3'
  match "/support" => redirect("https://desksnearme.desk.com")

end
