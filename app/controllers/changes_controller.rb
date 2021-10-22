# frozen_string_literal: true

class ChangesController < ApplicationController
  before_action :check_admin!, except: %i[index]
  before_action :set_change, only: %i[edit update]

  def index
    current_user&.update(last_read_change: Time.zone.now)
    @changes = Change.order(published_at: :desc)
  end

  def new
    @change = Change.new(published_at: Time.zone.today)
  end

  def edit; end

  def create
    @change = Change.new(change_params)

    if @change.save
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @change.update(change_params)
      redirect_to  action: :index
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_change
    @change = Change.find(params[:id])
  end

  def change_params
    params.require(:change).permit(:title, :body, :published_at)
  end
end
