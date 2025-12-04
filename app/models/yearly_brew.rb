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

  memo_wise def shots_count(year = :current)
    shots(year).count
  end

  memo_wise def shots_change_percentage
    return nil if shots_past_year.none?

    (((shots_count - shots_past_year.count) / shots_past_year.count.to_f) * 100).round(1)
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

  memo_wise def brew_days_count(year = :current)
    shots(year).distinct.count("DATE(start_time)")
  end

  memo_wise def longest_streak_days(year = :current)
    days = shots(year).select("DATE(start_time) AS day").distinct.order(:day).map { |d| d.day.to_date }
    return 0 if days.empty?

    max_streak = current_streak = 1
    days.each_cons(2) do |a, b|
      current_streak = b == a + 1 ? current_streak + 1 : 1
      max_streak = [max_streak, current_streak].max
    end
    max_streak
  end

  memo_wise def favorite_hour(year = :current)
    top_hour = shots(year)
      .select("EXTRACT(HOUR FROM start_time) AS hour, COUNT(*) AS shots_count")
      .group("hour")
      .order(shots_count: :desc)
      .first
    return unless top_hour

    hour = top_hour.hour.to_i
    average_minute = shots(year).where("EXTRACT(HOUR FROM start_time) = ?", hour).average("EXTRACT(MINUTE FROM start_time)")

    user_time = Time.utc(2025, 1, 1, hour, average_minute.to_f.round).in_time_zone(user.timezone.presence || Current.timezone.presence || "UTC")
    formatted = user_time.strftime("%H:%M")
    "#{formatted} (#{top_hour.shots_count} shots)"
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
      .order(:day)
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

  memo_wise def managed_shots_count(year = :current)
    managed_shots(year).count
  end

  memo_wise def managed_shots_ratio(year = :current)
    total = shots_count(year)
    return 0 if total.zero?

    ((managed_shots_count(year) / total.to_f) * 100).round(1)
  end

  memo_wise def managed_coffee_bags_count(year = :current)
    managed_shots(year).distinct.count(:coffee_bag_id)
  end

  memo_wise def managed_roasters_count(year = :current)
    managed_shots(year).joins(coffee_bag: :roaster).distinct.count("coffee_bags.roaster_id")
  end

  memo_wise def coffee_bags_added(year = :current)
    year_int = target_year(year)
    user.coffee_bags.where("extract(year from coffee_bags.created_at) = ?", year_int).count
  end

  memo_wise def coffee_bags_archived(year = :current)
    year_int = target_year(year)
    user.coffee_bags.where("extract(year from coffee_bags.archived_at) = ?", year_int).count
  end

  memo_wise def roasters_added(year = :current)
    year_int = target_year(year)
    user.roasters.where("extract(year from roasters.created_at) = ?", year_int).count
  end

  memo_wise def average_enjoyment_change
    previous = average_enjoyment(:past)
    return nil if previous.zero?

    (average_enjoyment - previous).round(1)
  end

  private

  def target_year(year)
    year == :past ? self.year - 1 : self.year
  end

  def shots(year)
    year == :past ? shots_past_year : shots_this_year
  end

  def managed_shots(year)
    shots(year).where.not(coffee_bag_id: nil)
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
