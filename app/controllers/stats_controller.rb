# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :check_admin!

  def index
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
    user_creations = User.order(:created_at).pluck(:created_at)
    user_data = {}
    total_users = 0
    user_creations.each do |creation|
      total_users += 1
      user_data[creation.to_date.to_time.to_i * 1000] = total_users
    end
    @user_chart = [{
      name: "User joins",
      data: User.order("created_at::date").group("created_at::date").count.map { |date, count| [date.to_time.to_i * 1000, count] }
    }, {
      name: "Total users",
      data: user_data.to_a
    }]

    @top_profiles_all_time = top_profiles(from: "1.1.2000".to_date)
    @top_profiles_last_month = top_profiles(from: 1.month.ago)
  end

  private

  def top_profiles(from:)
    profiles = Shot.where(created_at: from..).pluck(:profile_title)
    total = profiles.size.to_f
    profiles.map { |p| p.to_s.sub("Visualizer/", "") }.tally.sort_by { |_p, c| c }.last(20).reverse.to_h.transform_values { |c| (c / total * 100).round(2) }
  end
end
