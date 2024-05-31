class ShotsController < ApplicationController
  include CursorPaginatable

  FILTERS = %i[profile_title bean_brand bean_type grinder_model bean_notes espresso_notes].freeze

  before_action :authenticate_user!, except: %i[show compare share]
  before_action :load_shot, only: %i[show compare share remove_image]
  before_action :load_users_shot, only: %i[edit update destroy]
  before_action :load_users_shots, only: %i[index search]

  def search
    render :index
  end

  def show
    @shot.ensure_screenshot
    @chart = ShotChart.new(@shot, current_user) if @shot.information
    @related_shots = @shot.related_shots.pluck(:id, :profile_title, :start_time).sort_by { |s| s[2] }.reverse

    return if current_user.nil?

    @compare_shots = current_user.shots.where.not(id: @shot.id).by_start_time.limit(10).pluck(:id, :profile_title, :start_time)
  end

  def compare
    @comparison = Shot.find(params[:comparison])
    @chart = ShotChartCompare.new(@shot, @comparison, current_user) if @shot.information && @comparison.information
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
      instance_variable_set(:"@#{method.to_s.pluralize}", unique_values.sort_by(&:downcase))
    end
  end

  def create
    files = Array(params[:files])
    shots = files.map { |file| Shot.from_file(current_user, file.read) }

    if shots.all? { |shot| shot.save }
      flash[:notice] = "#{"Shot".pluralize(shots.count)} successfully uploaded."
    else
      flash[:alert] = if shots.any? { |shot| shot.errors[:base].present? && shot.errors.details[:base].any? { |e| e[:error] == :profile_file } }
        "You uploaded a profile file, not a history file. Please upload a history file."
      else
        {heading: "Could not save the provided #{"file".pluralize(files.count)}", text: shots.flat_map { |s| s.errors.full_messages.presence }.compact.uniq.join(" ")}
      end
    end
  rescue => e
    flash[:alert] = "Something went wrong: #{e.message}"
  ensure
    if params.key?(:drag)
      head :ok
    else
      redirect_to action: :index, format: :html
    end
  end

  def update
    @shot.update(update_shot_params)
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

  def coffee_bag_form
    @coffee_bag = CoffeeBag.find_by(id: params[:coffee_bag])
    @roasters = current_user.roasters.order_by_name.with_at_least_one_coffee_bag
    @roaster = params.key?(:roaster) ? current_user.roasters.find_by(id: params[:roaster]) : @coffee_bag&.roaster
    @coffee_bags = @roaster&.coffee_bags&.order_by_roast_date

    render layout: false
  end

  private

  def load_shot
    @shot = Shot.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to :root, alert: "Shot not found!"
  end

  def load_users_shot
    @shot = current_user.shots.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shots_path, alert: "Shot not found!"
  end

  def load_users_shots
    @shots = current_user.shots.with_attached_image

    unless current_user.premium?
      @premium_count = @shots.premium.count
      @shots = @shots.non_premium
    end
    @shots_count = @shots.count

    FILTERS.select { |f| params[f].present? }.each do |filter|
      @shots = @shots.where("#{filter} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[filter])}%")
    end
    @shots = @shots.where("espresso_enjoyment >= ?", params[:min_enjoyment]) if params[:min_enjoyment].to_i.positive?
    @shots = @shots.where("espresso_enjoyment <= ?", params[:max_enjoyment]) if params[:max_enjoyment].present? && params[:max_enjoyment].to_i < 100
    @shots = @shots.where(coffee_bag_id: params[:coffee_bag]) if params[:coffee_bag].present?

    @shots, @cursor = paginate_with_cursor(@shots.for_list, by: :start_time, before: params[:before])
  end

  def update_shot_params
    allowed = [:image, :profile_title, :barista, :bean_weight, :private_notes, *Parsers::Base::EXTRA_DATA_METHODS]
    allowed << {metadata: current_user.metadata_fields} if current_user.premium?
    allowed << :coffee_bag_id if current_user.coffee_management_enabled?
    params.require(:shot).permit(allowed)
  end
end
