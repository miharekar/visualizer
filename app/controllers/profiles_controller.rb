# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile

  def edit; end

  def update
    if @profile.update(profile_params)
      flash[:notice] = "Profile successfully updated."
      redirect_to controller: "shots", action: :index
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@profile, partial: "form") }
        format.html { render :edit }
      end
    end
  end

  private

  def set_profile
    @profile = params.key?(:id) && current_user.admin? ? User.find(params[:id]) : current_user
  end

  def profile_params
    allowed_params = %i[avatar name timezone skin public hide_shot_times]
    allowed_params << %i[github supporter] if current_user.admin?
    params.require(:user).permit(allowed_params)
  end
end
