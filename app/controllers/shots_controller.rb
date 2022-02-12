# frozen_string_literal: true

class ShotsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: %i[show compare chart share]
  before_action :load_shot, only: %i[show compare chart share]
  before_action :load_users_shot, only: %i[edit update destroy]

  def index
    load_shots_with_pagy
  end

  def show
    @shot.ensure_screenshot
    @chart = ShotChart.new(@shot, current_user&.chart_settings)
    return if current_user.nil?

    @compare_shots = current_user.shots.where.not(id: @shot.id).by_start_time.limit(20).pluck(:id, :profile_title, :start_time)
  rescue ActiveRecord::RecordNotFound
    redirect_to :root
  end

  def compare
    @comparison = Shot.find(params[:comparison])
    @chart = ShotChartCompare.new(@shot, @comparison, current_user&.chart_settings)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Comparison shot not found!"
    @shot ? redirect_to(@shot) : redirect_to(:root)
  end

  def chart
    @no_header = true
    @chart = ShotChart.new(@shot, current_user&.chart_settings)
  end

  def share
    share = SharedShot.find_or_initialize_by(shot: @shot, user: current_user)
    share.created_at = Time.zone.now
    share.save!
    render json: {code: share.code}
  end

  def create
    files = Array(params[:files])
    files.each do |file|
      Shot.from_file(current_user, file)&.save
    end

    flash[:notice] = "#{'Shot'.pluralize(files.count)} successfully uploaded."
    if params.key?(:drag)
      head :ok
    else
      redirect_to action: :index
    end
  end

  def edit
    shots = current_user.shots
    %i[grinder_model bean_brand bean_type].each do |method|
      unique_values = Rails.cache.fetch("#{shots.cache_key_with_version}/#{method}") { shots.distinct.pluck(method).compact }
      instance_variable_set("@#{method.to_s.pluralize}", unique_values.sort_by(&:downcase))
    end
  end

  def update
    @shot.update(shot_params)
    if params[:shot][:image].present? && current_user.premium?
      if ActiveStorage.variable_content_types.include?(params[:shot][:image].content_type)
        @shot.image.attach(params[:shot][:image])
      else
        flash[:alert] = "Image must be a valid image file."
      end
    end
    flash[:notice] = "Shot successfully updated."
    redirect_to action: :show
  end

  def destroy
    @shot.destroy!

    respond_to do |format|
      format.turbo_stream do
        if request.referer.ends_with?("shots/#{@shot.id}")
          flash[:notice] = "Shot successfully deleted."
          redirect_to action: :index
        else
          load_shots_with_pagy
          if @shots.any?
            render turbo_stream: turbo_stream.replace("shot-list", partial: "shots/list", locals: {shots: @shots, pagy: @pagy})
          else
            redirect_to action: :index
          end
        end
      end
      format.html do
        flash[:notice] = "Shot successfully deleted."
        redirect_to action: :index
      end
    end
  end

  private

  def load_shot
    @shot = Shot.find(params[:id])
  end

  def load_users_shot
    @shot = current_user.shots.find(params[:id])
  end

  def shot_params
    params.require(:shot).permit(:image, :profile_title, :bean_weight, *Shot::EXTRA_DATA_METHODS)
  end

  def load_shots_with_pagy
    @shots = current_user.shots.by_start_time
    @shots = @shots.where(created_at: 1.month.ago..) unless current_user.premium?
    @pagy, @shots = pagy(@shots)
  end
end
