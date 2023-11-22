# frozen_string_literal: true

class UpdatesController < ApplicationController
  include Pagy::Backend

  before_action :check_admin!, except: %i[index show]
  before_action :set_update, only: %i[show edit update]

  def index
    current_user&.update(last_read_change: Time.zone.now)
    @updates = Update.order(published_at: :desc)
    @pagy, @updates = pagy(@updates, items: 3)
  end

  def show
  end

  def new
    @update = Update.new(published_at: Time.zone.today)
  end

  def edit
  end

  def create
    @update = Update.new(update_params)

    if @update.save
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @update.update(update_params)
      redirect_to update_path(@update.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_update
    @update = Update.find_by_slug_or_id(params[:id]) # rubocop:disable Rails/DynamicFindBy
  end

  def update_params
    params.require(:update).permit(:title, :body, :published_at, :image, :excerpt)
  end
end
