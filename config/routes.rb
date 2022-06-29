# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}
  match "(*any)", to: redirect { |_, req| "https://visualizer.coffee#{req.fullpath}" }, via: :all, constraints: {host: "decent-visualizer.herokuapp.com"}

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
    mount PgHero::Engine => "pghero"
  end

  devise_for :users
  use_doorkeeper do
    controllers applications: "oauth/applications"
  end

  root to: "home#show"

  namespace :api do
    get :me, to: "credentials#me"
    resources :shots, only: [:index] do
      get :download
      get :profile
      collection do
        get :shared
        post :upload
      end
    end
  end

  get :people, to: "people#index"
  get "people/:slug", to: "people#show", as: :users_shots
  get :changelog, to: "changes#index"
  get :privacy, to: "home#privacy"
  post :stripe, to: "stripe#create"

  resources :shots, except: [:new] do
    member do
      get :chart
      get :share
      get "/compare/:comparison", to: "shots#compare"
    end
  end

  resources :search, only: [:index] do
    collection do
      get :autocomplete
    end
  end

  resources :profiles, only: %i[edit update] do
    get :reset_chart_settings
    get :edit, on: :collection
  end

  resources :premium, only: %i[index create] do
    post :update
    collection do
      get :success
      get :cancel
    end
  end

  resources :stats, only: [:index]
  resources :changes, except: %i[index destroy]
end
