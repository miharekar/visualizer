# frozen_string_literal: true

class ChangesController < ApplicationController
  include Pagy::Backend

  before_action :check_admin!, except: %i[index show]
  before_action :set_change, only: %i[show edit update]

  def index
    current_user&.update(last_read_change: Time.zone.now)
    @changes = Change.order(published_at: :desc)
    @pagy, @changes = pagy(@changes, items: 3)
  end

  def new
    @change = Change.new(published_at: Time.zone.today)
  end

  def edit; end

  def show; end

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
      redirect_to change_path(@change.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_change
    @change = Change.find_by_slug_or_id(params[:id]) # rubocop:disable Rails/DynamicFindBy
  end

  def change_params
    params.require(:change).permit(:title, :body, :published_at)
  end
end
