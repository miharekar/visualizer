# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}
  match "(*any)", to: redirect { |_, req| "https://visualizer.coffee#{req.fullpath}" }, via: :all, constraints: {host: "decent-visualizer.herokuapp.com"}

  root to: "home#show"
  get "/privacy", to: "home#privacy"

  namespace :api do
    resources :shots, only: [:index] do
      get :download
      collection do
        post :upload
      end
    end
  end

  authenticate :user, ->(user) { user.admin? } do
    mount GoodJob::Engine => "jobs"
  end

  devise_for :users

  resources :shots, except: [:new] do
    get :chart
  end

  resources :search, only: [:index]
  resources :stats, only: [:index]

  get :people, to: "people#index"
  get "people/:slug", to: "people#show", as: :users_shots

  resources :profiles, only: %i[edit update] do
    collection do
      get :edit
      patch :update
    end
  end
end
