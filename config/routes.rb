# frozen_string_literal: true

Rails.application.routes.draw do
  resources :shots, only: %i[show create]
end
