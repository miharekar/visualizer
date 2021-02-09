# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    @users = User.where(public: true).order(:name)
  end

  def show
    @user = User.find_by(slug: params[:slug])

    if @user.nil?
      user = User.find(params[:slug])
      return redirect_to users_shots_path(slug: user.slug), status: :moved_permanently
    end

    if @user.public
      @shots = @user.shots.order(start_time: :desc)
      @pagy, @shots = pagy(@shots)
    else
      redirect_to :root
    end
  end
end
