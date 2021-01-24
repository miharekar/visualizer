# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if current_user.update(profile_params)
      flash[:notice] = "Profile successfully updated."
      redirect_to controller: "shots", action: :index
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(current_user, partial: "form") }
        format.html { render :edit }
      end
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :skin, :public)
  end
end
