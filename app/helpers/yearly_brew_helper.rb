module YearlyBrewHelper
  def bento_box_stats_2024(yearly_brew, personal: true)
    {
      most_brewed_coffee: {
        title: personal ? "Your Go-To Bean" : "Go-To Bean",
        stat: yearly_brew.most_brewed_coffee,
        description: "When #{personal ? "you" : "they"} find The One, #{personal ? "you" : "they"} stick with it. This coffee kept #{personal ? "you" : "them"} coming back for more."
      },
      most_used_profile: {
        title: "Favorite Recipe",
        stat: yearly_brew.most_used_profile,
        description: "If it ain't broke, don't fix it. #{possessive(personal).capitalize} trusted path to coffee happiness."
      },
      best_rated_coffee: {
        title: "Crown Jewel",
        stat: yearly_brew.best_rated_coffee
      },
      weekly_rhythm: {
        title: "Weekly Grind",
        stat: yearly_brew.shots_per_day_of_week.to_json,
        description: "Some days need more coffee than others. Here's #{possessive(personal)} week in shots."
      },
      monthly_enjoyment: {
        title: "Month by Month Enjoyment",
        stat: yearly_brew.monthly_enjoyments.to_json,
        description: "#{possessive(personal).capitalize} coffee satisfaction journey through the seasons."
      },
      busiest_month: {
        title: "Peak Coffee Season",
        stat: yearly_brew.month_with_most_shots,
        description: "When #{possessive(personal)} grinder worked overtime and #{possessive(personal)} tamper knew no rest."
      },
      most_active_day: {
        title: "Power Day",
        stat: yearly_brew.day_with_most_shots,
        description: "The day when #{possessive(personal)} coffee game is strongest. Coincidence? I think not!"
      },
      coffee_brewed: {
        title: "Liquid Gold",
        stat: "#{yearly_brew.amount_brewed} kg",
        description: "The total amount of coffee in #{possessive(personal)} cup. That's a lot of caffeine!"
      }
    }
  end

  def bento_box_position_classes_2024(index)
    is_middle_row = [3, 4].include?(index)

    col_span = is_middle_row ? "lg:col-span-3" : "lg:col-span-2"

    rounded_corners = []
    rounded_corners << "max-lg:rounded-t-[2rem] lg:rounded-tl-[2rem]" if index == 0 # rubocop:disable Style/NumericPredicate
    rounded_corners << "lg:rounded-tr-[2rem]" if index == 2
    rounded_corners << "lg:rounded-bl-[2rem]" if index == 5
    rounded_corners << "max-lg:rounded-b-[2rem] lg:rounded-br-[2rem]" if index == 7

    {col_span:, rounded_corners: rounded_corners.join(" ")}
  end

  def possessive(personal)
    personal ? "your" : "their"
  end

  def summary_metrics_2025(yearly_brew, personal: true)
    [
      {
        label: "Shots pulled",
        value: yearly_brew.shots_count,
        detail: delta_badge(yearly_brew.shots_count - yearly_brew.shots_count(:past))
      },
      {
        label: "Avg enjoyment",
        value: yearly_brew.average_enjoyment.positive? ? "#{yearly_brew.average_enjoyment}" : "—",
        detail: delta_badge(yearly_brew.average_enjoyment_change)
      },
      {
        label: "Brew time",
        value: human_time(yearly_brew.time_brewed(human: true)),
        detail: "In #{yearly_brew.brew_days_count} days"
      },
      {
        label: "Coffee used",
        value: "#{yearly_brew.amount_beans_used} kg",
        detail: "#{yearly_brew.amount_brewed} kg brewed"
      }
    ]
  end

  def highlight_cards_2025(yearly_brew, personal: true)
    {
      favorite_roaster: {
        title: personal ? "Roaster crush" : "Roaster of the year",
        stat: yearly_brew.favorite_roaster,
        body: "The roaster that kept the grinder busy."
      },
      most_brewed_coffee: {
        title: "Most brewed coffee",
        stat: yearly_brew.most_brewed_coffee,
        body: "The trusty beans that fueled the caffeine habit."
      },
      most_used_profile: {
        title: "Signature recipe",
        stat: yearly_brew.most_used_profile,
        body: "The profile dialed in for consistent magic."
      },
      best_rated_coffee: {
        title: "Crown jewel",
        stat: yearly_brew.best_rated_coffee,
        body: "Top-scoring cup of the year."
      }
    }
  end

  def habit_cards_2025(yearly_brew, personal: true)
    [
      {
        label: "Brew days",
        value: yearly_brew.brew_days_count,
        description: "Days that started (or ended) with coffee."
      },
      {
        label: "Longest streak",
        value: yearly_brew.longest_streak_days,
        description: "Consecutive days of brewing momentum."
      },
      {
        label: "Prime time",
        value: yearly_brew.favorite_hour || "—",
        description: "When the machine worked hardest."
      },
      {
        label: "Peak day",
        value: yearly_brew.day_with_most_shots || "—",
        description: "The day the coffee was needed most."
      }
    ]
  end

  def coffee_management_cards_2025(yearly_brew, personal: true)
    [
      {
        label: "Shots with coffee bag",
        value: yearly_brew.managed_shots_count,
        description: "#{yearly_brew.managed_shots_ratio}% of all shots were linked to a bag."
      },
      {
        label: "Purchased",
        value: yearly_brew.managed_coffee_bags_count,
        description: "#{yearly_brew.coffee_bags_added} new coffee bags purchased this year."
      },
      {
        label: "Archived",
        value: yearly_brew.coffee_bags_archived,
        description: "Coffee bags finished and tucked away."
      }
    ]
  end

  def year_over_year_text(change, personal)
    return "#{possessive(personal).capitalize} baseline year" if change.nil?
    return "No change" if change.zero?

    change.positive? ? "+#{change}% vs last year" : "#{change}% vs last year"
  end

  def delta_badge(change)
    return "No change vs last year" if change.nil? || change.zero?

    change.positive? ? "+#{change} vs last year" : "#{change} vs last year"
  end

  def human_time(hours_minutes_seconds)
    hours, minutes, seconds = hours_minutes_seconds
    parts = []
    parts << "#{hours}h" if hours.positive?
    parts << "#{minutes}m" if minutes.positive?
    parts << "#{seconds}s" if seconds.positive? && parts.none?
    parts = ["0s"] if parts.empty?
    parts.join(" ")
  end
end
