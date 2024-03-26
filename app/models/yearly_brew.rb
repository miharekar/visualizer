class YearlyBrew
  prepend MemoWise

  attr_reader :shots_this_year, :shots_past_year

  def initialize(user, year: 2023)
    @shots_this_year = user.shots.where("extract(year from start_time) = ?", year)
    @shots_past_year = user.shots.where("extract(year from start_time) = ?", year - 1)
  end

  memo_wise def favorite_roaster(year = :current)
    roaster = most_common(shots(year), :bean_brand, exclude: {bean_brand: ["", "Unknown roaster"]}).first
    "#{roaster.bean_brand} (#{roaster.shots_count} shots)" if roaster
  end

  memo_wise def best_rated_coffee(year = :current)
    coffees = most_common(shots(year), %i[bean_brand bean_type espresso_enjoyment], exclude: {bean_brand: ["", "Unknown roaster"], bean_type: ["", "Unknown bean"], espresso_enjoyment: [nil, 0]})
    coffees = coffees.select { |c| c.shots_count > 1 }
    max = coffees.map(&:espresso_enjoyment).max
    coffee = coffees.select { |c| c.espresso_enjoyment == max }.max_by { |c| c.shots_count }
    "#{coffee.bean_brand} #{coffee.bean_type} (#{coffee.shots_count} shots with #{coffee.espresso_enjoyment})" if coffee
  end

  memo_wise def most_brewed_coffee(year = :current)
    coffee = most_common(shots(year), %i[bean_brand bean_type], exclude: {bean_brand: ["", "Unknown roaster"], bean_type: ["", "Unknown bean"]}).first
    "#{coffee.bean_brand} #{coffee.bean_type} (#{coffee.shots_count} shots)" if coffee
  end

  memo_wise def most_used_profile(year = :current)
    profile = most_common(shots(year), :profile_title, exclude: {profile_title: ["", "Unknown profile"]}).first
    "#{profile.profile_title} (#{profile.shots_count} shots)" if profile
  end

  memo_wise def average_enjoyment(year = :current)
    shots(year).where.not(espresso_enjoyment: [nil, 0]).average(:espresso_enjoyment).to_f.round(2)
  end

  memo_wise def time_brewed(year = :current)
    (shots(year).sum(:duration) / 60).round(2)
  end

  memo_wise def amount_beans_used(year = :current)
    (shots(year).sum { |s| s.bean_weight.to_f } / 1000).round(3)
  end

  memo_wise def amount_brewed(year = :current)
    (shots(year).sum { |s| s.drink_weight.to_f } / 1000).round(3)
  end

  memo_wise def month_with_most_shots(year = :current)
    month = most_common(shots(year), "EXTRACT(MONTH FROM start_time)").first
    "#{Date::MONTHNAMES[month.extract.to_i]} (#{month.shots_count})" if month
  end

  memo_wise def day_with_most_shots(year = :current)
    day = most_common(shots(year), "EXTRACT(DOW FROM start_time)").first
    "#{Date::DAYNAMES[day.extract.to_i]} (#{day.shots_count})" if day
  end

  private

  def shots(year)
    (year == :past) ? shots_past_year : shots_this_year
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
