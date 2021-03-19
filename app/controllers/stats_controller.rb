# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to :shots unless current_user.admin?

    @shot_count = Shot.count
    @user_count = User.count
    @shot_chart = [{
      name: "Shots per day",
      data: Shot.order("created_at::date").group("created_at::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }]
  end
end
