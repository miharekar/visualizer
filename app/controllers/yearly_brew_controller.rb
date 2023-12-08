# frozen_string_literal: true

class YearlyBrewController < ApplicationController
  before_action :authenticate_user!

  def index
    @shots_2023 = current_user.shots.where("extract(year from start_time) = ?", 2023)
    @shots_2022 = current_user.shots.where("extract(year from start_time) = ?", 2022)

    @coffee_2023 = most_used_coffee(@shots_2023)
    @coffee_2022 = most_used_coffee(@shots_2022)

    @fav_roaster_2023 = favorite_roaster(@shots_2023)
    @fav_roaster_2022 = favorite_roaster(@shots_2022)

    @most_used_profile_2023 = most_used_profile(@shots_2023)
    @most_used_profile_2022 = most_used_profile(@shots_2022)

    @best_rated_coffee_2023 = best_rated_coffee(@shots_2023)
    @best_rated_coffee_2022 = best_rated_coffee(@shots_2022)

    @average_enjoyment_2023 = average_enjoyment(@shots_2023).to_f.round(2)
    @average_enjoyment_2022 = average_enjoyment(@shots_2022).to_f.round(2)

    @time_brewed_2023 = (@shots_2023.sum(:duration) / 60).round(2)
    @time_brewed_2022 = (@shots_2022.sum(:duration) / 60).round(2)

    @amount_used_2023 = (@shots_2023.sum { |s| s.bean_weight.to_f } / 1000).round(3)
    @amount_used_2022 = (@shots_2022.sum { |s| s.bean_weight.to_f } / 1000).round(3)

    @amount_brewed_2023 = (@shots_2023.sum { |s| s.drink_weight.to_f } / 1000).round(3)
    @amount_brewed_2022 = (@shots_2022.sum { |s| s.drink_weight.to_f } / 1000).round(3)

    @month_with_most_shots_2023 = month_with_most_shots(@shots_2023)
    @month_with_most_shots_2022 = month_with_most_shots(@shots_2022)

    @day_with_most_shots_2023 = day_with_most_shots(@shots_2023)
    @day_with_most_shots_2022 = day_with_most_shots(@shots_2022)
  end

  private

  def most_used_coffee(shots)
    coffee = most_common(shots, %i[bean_brand bean_type], exclude: {bean_brand: ["", "Unknown roaster"], bean_type: ["", "Unknown bean"]}).first
    "#{coffee.bean_brand} #{coffee.bean_type} (#{coffee.shots_count} shots)" if coffee
  end

  def favorite_roaster(shots)
    roaster = most_common(shots, :bean_brand, exclude: {bean_brand: ["", "Unknown roaster"]}).first
    "#{roaster.bean_brand} (#{roaster.shots_count} shots)" if roaster
  end

  def most_used_profile(shots)
    profile = most_common(shots, :profile_title, exclude: {profile_title: ["", "Unknown profile"]}).first
    "#{profile.profile_title} (#{profile.shots_count} shots)" if profile
  end

  def best_rated_coffee(shots)
    coffees = most_common(shots, %i[bean_brand bean_type espresso_enjoyment], exclude: {bean_brand: ["", "Unknown roaster"], bean_type: ["", "Unknown bean"], espresso_enjoyment: [nil, 0]})
    coffees = coffees.select { |c| c.shots_count > 1 }
    max = coffees.map(&:espresso_enjoyment).max
    coffee = coffees.select { |c| c.espresso_enjoyment == max }.max_by { |c| c.shots_count }
    "#{coffee.bean_brand} #{coffee.bean_type} (#{coffee.shots_count} shots with #{coffee.espresso_enjoyment})" if coffee
  end

  def average_enjoyment(shots)
    shots.where.not(espresso_enjoyment: [nil, 0]).average(:espresso_enjoyment)
  end

  def month_with_most_shots(shots)
    month = most_common(shots, "EXTRACT(MONTH FROM start_time)").first
    "#{Date::MONTHNAMES[month.extract.to_i]} (#{month.shots_count})" if month
  end

  def day_with_most_shots(shots)
    day = most_common(shots, "EXTRACT(DOW FROM start_time)").first
    "#{Date::DAYNAMES[day.extract.to_i]} (#{day.shots_count})" if day
  end

  def most_common(shots, attributes, exclude: {})
    attributes = Array(attributes)
    query = shots.select(*attributes, "COUNT(*) AS shots_count")
      .group(*attributes)
      .order(shots_count: :desc)

    exclude.each do |attribute, values|
      query = query.where.not(attribute => values) if values.present?
    end

    query
  end
end
