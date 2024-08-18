Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}

  authenticate :user, ->(user) { user.admin? } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgHero::Engine, at: "/pghero"
  end

  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}

  use_doorkeeper do
    controllers applications: "oauth/applications"
  end

  root to: "home#show"

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
    end
    delete :remove_image, on: :member
    post :search, on: :collection
  end

  resources :community, only: [:index] do
    collection do
      get :autocomplete
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

  resources :yearly_brew, only: %i[index show]
  resources :stats, only: [:index]
  resources :customers, only: %i[index ]
  resources :updates, except: %i[destroy] do
    get :feed, on: :collection
  end
  get "/changes(/*path)", to: redirect { |params| "/updates/#{params[:path]}" }

  post :airtable, to: "airtable#notification"

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  get "/up" => "rails/health#show", :as => :rails_health_check
end
