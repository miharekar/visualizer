class YearlyBrewController < ApplicationController
  before_action :require_authentication, except: [:show]

  def index
    year = (params[:year].presence || 2023).to_i
    @yearly_brew = YearlyBrew.new(Current.user, year:)
  end

  def show
    @user = User.visible.find_by(slug: params[:id])

    if @user
      @yearly_brew = YearlyBrew.new(@user, year: 2023)
    else
      flash[:alert] = "Yearly Brew not found"
      if Current.user
        redirect_to action: :index
      else
        redirect_to root_path
      end
    end
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
    coffee = coffees.select { |c| c.espresso_enjoyment == max }.max_by(&:shots_count)
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
