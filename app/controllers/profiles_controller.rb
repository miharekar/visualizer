# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if current_user.update(profile_params)
      flash[:notice] = "Profile succesfully updated."
      redirect_to shots_path
    else
      render :edit
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :skin, :public)
  end
end
