# frozen_string_literal: true

class ShotsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: %i[show compare share]
  before_action :load_shot, only: %i[show compare share remove_image]
  before_action :load_users_shot, only: %i[edit update destroy]

  def index
    load_shots_with_pagy
  end

  def recents
    @recents = current_user.shots.by_start_time.
      where(start_time: 3.weeks.ago..).
      group_by { |s| [s.bean_brand, s.bean_type] }.
      first(5).
      map do |bean_group, shots|
      [bean_group, shots.group_by { |s| [s.grinder_model, s.profile_title] }]
    end
  end

  def enjoyments
    enjoyments = current_user.shots.by_start_time.
      where("espresso_enjoyment > 0").
      where(created_at: 6.months.ago..)
    @enjoyments_data = EnjoymentChart.new(enjoyments).chart
  end

  def show
    @shot.ensure_screenshot
    @chart = ShotChart.new(@shot, current_user)
    @related_shots = @shot.related_shots.pluck(:id, :profile_title, :start_time).sort_by { |s| s[2] }.reverse

    return if current_user.nil?

    @compare_shots = current_user.shots.where.not(id: @shot.id).by_start_time.limit(10).pluck(:id, :profile_title, :start_time)
  rescue ActiveRecord::RecordNotFound
    redirect_to :root
  end

  def compare
    @comparison = Shot.find(params[:comparison])
    @chart = ShotChartCompare.new(@shot, @comparison, current_user)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Comparison shot not found!"
    redirect_to(@shot || :root)
  end

  def share
    share = SharedShot.find_or_initialize_by(shot: @shot, user: current_user)
    share.created_at = Time.zone.now
    share.save!
    render json: {code: share.code}
  end

  def edit
    shots = current_user.shots
    %i[grinder_model bean_brand bean_type].each do |method|
      unique_values = Rails.cache.fetch("#{shots.cache_key_with_version}/#{method}") { shots.distinct.pluck(method).select(&:present?) }
      instance_variable_set("@#{method.to_s.pluralize}", unique_values.sort_by(&:downcase))
    end
  end

  def create
    files = Array(params[:files])
    shots = files.map { |file| Shot.from_file(current_user, file) }

    if shots.all? { |s| s.errors.empty? }
      shots.each(&:save!)
      flash[:notice] = "#{"Shot".pluralize(shots.count)} successfully uploaded."
    else
      flash[:alert] = if shots.any? { |shot| shot.errors[:base].present? && shot.errors.details[:base].any? { |e| e[:error] == :profile_file } }
        "You uploaded a profile file, not a history file. Please upload a history .shot or .json file."
      else
        "You uploaded invalid #{"file".pluralize(files.count)}."
      end
    end

    if params.key?(:drag)
      head :ok
    else
      redirect_to action: :index
    end
  end

  def update
    allowed = [:image, :profile_title, :barista, :bean_weight, :private_notes, *Shot::EXTRA_DATA_METHODS]
    allowed << {metadata: current_user.metadata_fields} if current_user.premium?
    @shot.update(params.require(:shot).permit(allowed))
    if params[:shot][:image].present? && current_user.premium?
      if ActiveStorage.variable_content_types.include?(params[:shot][:image].content_type)
        @shot.image.attach(params[:shot][:image])
      else
        flash.now[:alert] = "Image must be a valid image file."
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
            render turbo_stream: turbo_stream.replace("shot-list", partial: "shots/list", locals: {shots: @shots, pagy: @pagy, include_person: false})
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

  def remove_image
    @shot.image.purge
    render turbo_stream: turbo_stream.remove("shot-image")
  end

  private

  def load_shot
    @shot = Shot.find(params[:id])
  end

  def load_users_shot
    @shot = current_user.shots.find(params[:id])
  end

  def load_shots_with_pagy
    @shots = current_user.shots.by_start_time
    @shots = @shots.non_premium unless current_user.premium?
    @shots_count = @shots.count
    @pagy, @shots = pagy_countless(@shots)
  end
end
