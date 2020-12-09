# frozen_string_literal: true

Rails.application.routes.draw do
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: {subdomain: "www"}

  root "shots#new"

  resources :shots, only: %i[show new create] do
    get :random, on: :collection
  end
end
