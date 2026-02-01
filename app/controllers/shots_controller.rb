class ShotsController < ApplicationController
  include Filterable
  include Paginatable
  include Shots::Editing

  before_action :require_authentication, except: %i[show compare share beanconqueror]
  before_action :load_shot, only: %i[show compare remove_image share beanconqueror]
  before_action :create_shared_shot, only: %i[share beanconqueror]
  before_action :load_users_shot, only: %i[edit update destroy]
  before_action :load_coffee_bags_for_form, only: :edit
  before_action :load_users_shots, only: %i[index search]
  before_action :load_related_shots, only: %i[show edit]

  def index; end

  def search
    render :index
  end

  def show
    @chart = ShotChart.new(@shot, Current.user) if @shot.information
  end

  def compare
    @comparison = Shot.find(params[:comparison])
    @chart = ShotChartCompare.new(@shot, @comparison, Current.user) if @shot.information && @comparison.information
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Comparison shot not found!"
    redirect_to(@shot || :root)
  end

  def share
    render json: {code: @shared_shot.code}
  end

  def beanconqueror
    redirect_to "https://beanconqueror.com?visualizerShare=#{@shared_shot.code}", allow_other_host: true
  end

  def edit
    authorize @shot
  end

  def create
    files = Array(params[:files])
    shots = files.map { |file| Shot.from_file(Current.user, file.read) }

    if shots.all?(&:save)
      flash[:notice] = "#{"Shot".pluralize(shots.count)} successfully uploaded."
    else
      flash[:alert] = if shots.any? { |shot| shot.errors[:base].present? && shot.errors.details[:base].any? { |e| e[:error] == :profile_file } }
        "You uploaded a profile file, not a history file. Please upload a history file."
      else
        {heading: "Could not save the provided #{"file".pluralize(files.count)}", text: shots.flat_map { |s| s.errors.full_messages.presence }.compact.uniq.join(" ")}
      end
    end
  rescue StandardError => e
    flash[:alert] = "Something went wrong: #{e.message}"
  ensure
    if params.key?(:drag)
      head :ok
    else
      redirect_to action: :index, format: :html
    end
  end

  def update
    authorize @shot
    @shot.update(update_shot_params)
    apply_brewdata_updates
    attach_image(params.dig(:shot, :image)) if Current.user.premium?
    flash[:notice] = "Shot successfully updated."
  rescue Shots::Editing::InvalidImageError => e
    flash[:alert] = e.message
  ensure
    redirect_to action: :show
  end

  def destroy
    authorize @shot
    @shot.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(@shot)
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
  rescue ActiveRecord::RecordNotFound
    redirect_to :root, alert: "Shot not found!"
  end

  def load_users_shot
    @shot = Current.user.shots.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shots_path, alert: "Shot not found!"
  end

  def load_users_shots
    @shots = Current.user.shots.with_attached_image

    if Current.user.premium?
      apply_standard_filters_to_shots
      if params[:all_notes].present?
        notes = "%#{ActiveRecord::Base.sanitize_sql_like(params[:all_notes])}%"
        @shots = @shots.where("bean_notes ILIKE :notes OR espresso_notes ILIKE :notes OR private_notes ILIKE :notes", notes:)
      end
      @coffee_bag = Current.user.coffee_bags.find_by(id: params[:coffee_bag]) if params[:coffee_bag].present?
      @shots = @shots.where(coffee_bag_id: @coffee_bag.id) if @coffee_bag
      @shots = @shots.where(id: ShotTag.joins(:tag).where(tag: {slug: params[:tag]}).select(:shot_id)) if params[:tag].present?
    else
      @premium_count = @shots.premium.count
      @shots = @shots.non_premium
    end
    @shots_count = @shots.count

    @shots, @cursor = paginate_with_cursor(@shots.for_list, by: :start_time, before: params[:before])
  end

  def load_related_shots
    @related_shots = @shot.related_shots.pluck(:id, :profile_title, :bean_type, :start_time).sort_by { it[3] }.reverse
  end

  def load_coffee_bags_for_form
    return unless Current.user.coffee_management_enabled?

    @coffee_bags = Current.user.coffee_bags.active.by_roast_date.includes(:roaster).to_a
    @coffee_bags << @shot.coffee_bag if @shot&.coffee_bag && @coffee_bags.exclude?(@shot.coffee_bag)
  end

  def create_shared_shot
    @shared_shot = SharedShot.find_or_initialize_by(shot: @shot, user: Current.user)
    @shared_shot.created_at = Time.current
    @shared_shot.save!
  end
end
