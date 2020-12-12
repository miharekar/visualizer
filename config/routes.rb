# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}

  devise_for :users

  root "shots#new"

  resources :shots, only: %i[show new create index] do
    get :random, on: :collection
  end
end
