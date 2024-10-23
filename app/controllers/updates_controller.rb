class UpdatesController < ApplicationController
  include CursorPaginatable

  before_action :check_admin!, except: %i[index feed show]
  before_action :set_update, only: %i[show edit update]

  def index
    Current.user&.update(last_read_change: Time.current)
    @updates, @cursor = paginate_with_cursor(Update, items: 3, by: :published_at, before: params[:before])
  end

  def feed
    @updates = Update.order(published_at: :desc)
    render formats: :rss
  end

  def show
    redirect_to updates_path, alert: "Update not found" unless @update
  end

  def new
    @update = Update.new(published_at: Time.zone.today)
  end

  def edit; end

  def create
    @update = Update.new(update_params)

    if @update.save
      redirect_to updates_path(format: :html)
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
