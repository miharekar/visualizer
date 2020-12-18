# frozen_string_literal: true

class PeopleController < ApplicationController
  def index
    @users = User.where(public: true)
  end

  def show
    @user = User.find(params[:id])

    if @user.public
      @shots = @user.shots.order(start_time: :desc)
    else
      redirect_to :root
    end
  end
end
