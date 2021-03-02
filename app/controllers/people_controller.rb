# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    @users = User.visible.order(:name).with_attached_avatar
    @counts = Shot.visible.group(:user_id).count
  end

  def show
    @user = User.find_by(slug: params[:slug])

    if @user.nil?
      @user = User.find(params[:slug])
      return redirect_to users_shots_path(slug: @user.slug), status: :moved_permanently if @user.public?
    end

    if @user.public
      @shots = @user.shots.order(start_time: :desc)
      @pagy, @shots = pagy(@shots)
    else
      redirect_to :root
    end
  end
end
