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
  end
end
