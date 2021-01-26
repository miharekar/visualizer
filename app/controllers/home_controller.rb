# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    redirect_to :shots if user_signed_in?
  end
end
