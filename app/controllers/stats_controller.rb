class StatsController < ApplicationController
  before_action :require_authentication
  before_action :check_admin!

  def index
    @shot_count = Shot.count
    @user_count = User.count
    @shot_charts = [
      {name: "Uploaded files per day", data: get_stats(Shot, "day")},
      {name: "Uploaded files per week", data: get_stats(Shot, "week")},
      {name: "Uploaded files per month", data: get_stats(Shot, "month")}
    ]
    @user_charts = [
      {name: "Daily User joins", data: get_stats(User, "day")},
      {name: "Weekly User joins", data: get_stats(User, "week")},
      {name: "Monthly User joins", data: get_stats(User, "month")},
      {name: "Total users", data: total_users}
    ]
  end

  private

  def get_stats(klass, duration)
    klass
      .with(duration => klass.select("DATE_TRUNC('#{duration}', created_at) as #{duration}"))
      .from(duration)
      .group(duration)
      .order(duration)
      .count
      .map { |time, count| [time.to_i * 1000, count] }
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
