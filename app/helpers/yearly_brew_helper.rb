module YearlyBrewHelper
  def bento_box_stats_2024(yearly_brew)
    {
      most_brewed_coffee: {
        title: "Your Go-To Bean",
        stat: yearly_brew.most_brewed_coffee,
        description: "When you find The One, you stick with it. This coffee kept you coming back for more."
      },
      most_used_profile: {
        title: "Favorite Recipe",
        stat: yearly_brew.most_used_profile,
        description: "If it ain't broke, don't fix it. Your trusted path to coffee happiness."
      },
      best_rated_coffee: {
        title: "Crown Jewel",
        stat: yearly_brew.best_rated_coffee
      },
      weekly_rhythm: {
        title: "Weekly Grind",
        stat: yearly_brew.shots_per_day_of_week.to_json,
        description: "Some days need more coffee than others. Here's your week in shots."
      },
      monthly_enjoyment: {
        title: "Month by Month",
        stat: yearly_brew.monthly_enjoyments.to_json,
        description: "Your coffee satisfaction journey through the seasons."
      },
      busiest_month: {
        title: "Peak Coffee Season",
        stat: yearly_brew.month_with_most_shots,
        description: "When your grinder worked overtime and your tamper knew no rest."
      },
      most_active_day: {
        title: "Power Day",
        stat: yearly_brew.day_with_most_shots,
        description: "The day when your coffee game is strongest. Coincidence? I think not!"
      },
      coffee_brewed: {
        title: "Liquid Gold",
        stat: "#{yearly_brew.amount_brewed} kg",
        description: "The total amount of coffee in your cup. That's a lot of caffeine!"
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
end
