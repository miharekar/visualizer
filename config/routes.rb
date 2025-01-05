Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}

  constraints ->(request) { AuthConstraint.admin?(request) } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgHero::Engine, at: "/pghero"
  end

  use_doorkeeper do
    controllers applications: "oauth/applications"
  end

  root to: "home#show"

  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]
  resources :registrations, only: %i[new create]

  get "auth/airtable/callback", to: "omniauth_callbacks#airtable"
  get "auth/airtable", as: :connect_airtable
  get "auth/failure", to: "sessions#omniauth_failure"

  namespace :api do
    get :me, to: "credentials#me"
    resources :shots, only: %i[show index destroy] do
      get :download
      get :profile
      collection do
        get :shared
        post :upload
      end
    end
    resources :roasters, only: %i[index show] do
      resources :coffee_bags, only: %i[index show]
    end
  end

  get :heartbeat, to: "heartbeat#show"
  get :privacy, to: "home#privacy"
  post :stripe, to: "stripe#create"
  post "emails/unsubscribe"

  resources :people, only: %i[show] do
    get :feed, on: :member
  end

  resources :shots, except: [:new] do
    member do
      delete :remove_image
      get :share
      get :beanconqueror
      get "/compare/:comparison", to: "shots#compare"
    end
    collection do
      post :search
      get :coffee_bag_form
    end
  end

  resources :roasters, except: [:show] do
    resources :coffee_bags, except: [:show] do
      delete :remove_image, on: :member
      post :search, on: :collection
      post :duplicate, on: :member
      post :scrape_info, on: :collection
    end
    delete :remove_image, on: :member
    post :search, on: :collection
  end

  resources :community, only: [:index] do
    collection do
      get :autocomplete
      get :banner
    end
  end
  get "/search", to: redirect("/community")

  resources :profiles, only: %i[edit update] do
    get :reset_chart_settings
    get :decent_serial_numbers
    collection do
      get :edit
      post :add_metadata_field
      delete :remove_metadata_field
      delete :disconnect_airtable
    end
  end

  resources :premium, only: %i[index create] do
    collection do
      get :manage
      get :success
      get :cancel
    end
  end

  resources :decent_tokens, only: %i[new create]

  resources :push_subscriptions, only: %i[create]

  slug_constraint = ->(r) { r.params[:x].present? && YearlyBrewController::WHITELISTED_YEARS.map(&:to_s).exclude?(r.params[:x]) }
  get "yearly_brew", to: redirect("/yearly_brew/2023"), as: :yearly_brew_redirect
  get "yearly_brew/:x", to: redirect { |params| "/yearly_brew/#{params[:x]}/2023" }, constraints: slug_constraint
  get "yearly_brew(/:year)", to: "yearly_brew#index", as: :yearly_brew_index
  get "yearly_brew/:slug(/:year)", to: "yearly_brew#show", as: :yearly_brew

  resources :stats, only: [:index]
  resources :customers, only: %i[index]
  resources :updates, except: %i[destroy] do
    get :feed, on: :collection
  end
  get "/changes(/*path)", to: redirect { |params| "/updates/#{params[:path]}" }

  post :airtable, to: "airtable#notification"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  get "/up" => "rails/health#show", :as => :rails_health_check
end
