# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to :shots unless current_user.admin?

    @shot_count = Shot.count
    @user_count = User.count
    @uploaded_chart = [{
      name: "Uploaded .shot files per day",
      data: Shot.where(created_at: (..Time.zone.today)).order("created_at::date").group("created_at::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }]
    @brewed_chart = [{
      name: "Shots brewed on day",
      data: Shot.where(start_time: (("1.1.2020".to_date)..Time.zone.today)).order("start_time::date").group("start_time::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }]
    @deleted_chart = [{
      name: "Shots deleted on day",
      data: Shot.deleted.order("deleted_at::date").group("deleted_at::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }]
    @user_chart = [{
      name: "User joins",
      data: User.order("created_at::date").group("created_at::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }]
  end
end
