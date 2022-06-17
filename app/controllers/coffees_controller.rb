# frozen_string_literal: true

class CoffeesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def index
    @coffees = Coffee.all
    @pagy, @coffees = pagy(@coffees)
  end

  def show
    @coffee = Coffee.find(params[:id])
  end
end
