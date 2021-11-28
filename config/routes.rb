# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}
  match "(*any)", to: redirect { |_, req| "https://visualizer.coffee#{req.fullpath}" }, via: :all, constraints: {host: "decent-visualizer.herokuapp.com"}

  root to: "home#show"
  get "/privacy", to: "home#privacy"

  namespace :api do
    resources :shots, only: [:index] do
      get :download
      get :profile
      collection do
        get :shared
        post :upload
      end
    end
  end

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users

  get :people, to: "people#index"
  get "people/:slug", to: "people#show", as: :users_shots
  get :changelog, to: "changes#index"

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

  resources :stats, only: [:index]
  resources :sponsorships, only: [:create]
  resources :changes, except: %i[index show destroy]
end
