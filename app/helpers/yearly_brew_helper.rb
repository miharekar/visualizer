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
        title: "Month by Month",
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
end
