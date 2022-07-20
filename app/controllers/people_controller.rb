# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    @users = current_user&.admin? ? User.all : User.visible.with_attached_avatar
    @users = @users.by_name
    @counts = Shot.visible.group(:user_id).count
  end

  def show
    @user = User.find_by(slug: params[:slug])

    if @user.nil?
      @user = User.find_by(id: params[:slug])
      return redirect_to people_path, alert: "User #{params[:slug]} was not found" if @user.nil?
      return redirect_to users_shots_path(slug: @user.slug), status: :moved_permanently if @user.public?
    end

    if @user.public
      @shots = @user.shots.by_start_time
      @pagy, @shots = pagy_countless(@shots)
    else
      redirect_to :root
    end
  end
end
