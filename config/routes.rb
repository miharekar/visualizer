# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}

  devise_for :users

  unauthenticated do
    root "shots#new"
  end

  authenticated :user do
    root "shots#index", as: :authenticated_root
  end

  resources :shots, only: %i[show new create index destroy] do
    get :random, on: :collection
  end
end
