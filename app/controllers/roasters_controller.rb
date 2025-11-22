class RoastersController < ApplicationController
  before_action :require_authentication
  before_action :check_premium!
  before_action :set_roaster, only: %i[edit update destroy remove_image]

  def new
    @roaster = Current.user.roasters.build
  end

  def edit; end

  def create
    @roaster = Current.user.roasters.build(roaster_params)
    if @roaster.save
      redirect_to coffee_bags_path(roaster_id: @roaster.id, format: :html), notice: "Roaster was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @roaster.update(roaster_params)
      redirect_to coffee_bags_path(roaster_id: @roaster.id, format: :html), notice: "Roaster was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @roaster.destroy!
    redirect_to coffee_bags_path(format: :html), notice: "Roaster was successfully deleted."
  end

  def remove_image
    @roaster.image.purge
    render turbo_stream: turbo_stream.remove("roaster-image")
  end

  private

  def set_roaster
    @roaster = Current.user.roasters.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to coffee_bags_path, alert: "Roaster not found"
  end

  def roaster_params
    params.expect(roaster: %i[name website image canonical_roaster_id])
  end
end
