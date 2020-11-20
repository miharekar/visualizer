# frozen_string_literal: true

Rails.application.routes.draw do
  root "shots#new"

  resources :shots, only: %i[show new create]
end
