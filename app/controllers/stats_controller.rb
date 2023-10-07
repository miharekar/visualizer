# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :check_admin!

  def index
    @shot_count = Shot.count
    @user_count = User.count
    @uploaded_chart = [{name: "Uploaded .shot files per week", data: weekly_uploads}]
    @user_chart = [{
      name: "User joins",
      data: user_joins
    }, {
      name: "Total users",
      data: total_users
    }]
  end

  private

  def weekly_uploads
    Shot
      .with(weeks: Shot.select("DATE_TRUNC('week', created_at) as week"))
      .from("weeks")
      .group(:week)
      .count
      .map { |week, count| [week.to_i * 1000, count] }
      .sort_by(&:first)
  end

  def user_joins
    User.order(:created_at).group(:created_at).count.map { |date, count| [date.to_i * 1000, count] }
  end

  def total_users
    User
      .with(
        user_counts: User.select("DATE_TRUNC('day', created_at) as day, COUNT(*) as daily_count").group("DATE_TRUNC('day', created_at)"),
        cumulative_counts: User.from("user_counts").select("day, SUM(daily_count) OVER (ORDER BY day) as cumulative_count")
      )
      .from("cumulative_counts")
      .select("day, cumulative_count")
      .order("day")
      .map { |row| [row.day.to_i * 1000, row.cumulative_count.to_i] }
  end
end
