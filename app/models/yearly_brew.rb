class YearlyBrew
  prepend MemoWise

  attr_reader :user, :year

  def initialize(user, year)
    @user = user
    @year = year
  end

  memo_wise def shots_this_year
    user.shots.where("extract(year from start_time) = ?", year)
  end

  memo_wise def shots_past_year
    user.shots.where("extract(year from start_time) = ?", year - 1)
  end

  memo_wise def favorite_roaster(year = :current)
    roaster = most_common(shots(year), :bean_brand, exclude: {bean_brand: ["", "Unknown roaster"]}).first
    "#{roaster.bean_brand} (#{roaster.shots_count} shots)" if roaster
  end

  memo_wise def best_rated_coffee(year = :current)
    coffees = most_common(shots(year), %i[bean_brand bean_type espresso_enjoyment], exclude: {bean_brand: ["", "Unknown roaster"], bean_type: ["", "Unknown bean"], espresso_enjoyment: [nil, 0]})
    max = coffees.map(&:espresso_enjoyment).max
    coffees.select { |c| c.espresso_enjoyment == max }.max_by(&:shots_count)
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

  memo_wise def time_brewed(year = :current, human: false)
    total_seconds = shots(year).sum(:duration)
    if human
      hours = (total_seconds / 3600).floor
      minutes = ((total_seconds % 3600) / 60).floor
      seconds = (total_seconds % 60).round
      [hours, minutes, seconds]
    else
      (total_seconds / 60.0).round(2)
    end
  end

  memo_wise def amount_beans_used(year = :current)
    (shots(year).sum { it.bean_weight.to_f } / 1000).round(2)
  end

  memo_wise def amount_brewed(year = :current)
    (shots(year).sum { it.drink_weight.to_f } / 1000).round(2)
  end

  memo_wise def month_with_most_shots(year = :current)
    month = most_common(shots(year), "EXTRACT(MONTH FROM start_time)").first
    "#{Date::MONTHNAMES[month.extract.to_i]} (#{month.shots_count})" if month
  end

  memo_wise def day_with_most_shots(year = :current)
    day = most_common(shots(year), "EXTRACT(DOW FROM start_time)").first
    "#{Date::DAYNAMES[day.extract.to_i]} (#{day.shots_count})" if day
  end

  memo_wise def shots_per_day_of_week(year = :current)
    shots(year)
      .group("EXTRACT(DOW FROM start_time)")
      .select("EXTRACT(DOW FROM start_time) as day, COUNT(*) as shots_count")
      .order("day")
      .map { [Date::DAYNAMES[it.day.to_i], it.shots_count] }
      .rotate(1)
  end

  memo_wise def monthly_enjoyments(year = :current)
    monthly_data = shots(year)
      .where.not(espresso_enjoyment: [nil, 0])
      .group("EXTRACT(MONTH FROM start_time)")
      .select("EXTRACT(MONTH FROM start_time) as month, AVG(espresso_enjoyment) as avg_enjoyment")
      .to_h { |r| [r.month.to_i, r.avg_enjoyment] }

    (1..12).map do |month|
      [Date::MONTHNAMES[month], monthly_data[month].to_f.round(2)]
    end
  end

  private

  def shots(year)
    year == :past ? shots_past_year : shots_this_year
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
