# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}
  match "(*any)", to: redirect { |_, req| "https://visualizer.coffee#{req.fullpath}" }, via: :all, constraints: {host: "decent-visualizer.herokuapp.com"}

  namespace :api do
    resources :shots, only: [] do
      collection do
        post :upload
      end
    end
  end

  devise_for :users

  unauthenticated do
    root "shots#new"
  end

  authenticated :user do
    root "shots#index", as: :authenticated_root
  end

  resources :shots do
    collection do
      get :random
      post :bulk
    end
  end
end
