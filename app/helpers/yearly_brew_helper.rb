module YearlyBrewHelper
  def bento_box_stats_2024(yearly_brew)
    {
      most_brewed_coffee: {
        title: "Most Brewed Coffee",
        stat: yearly_brew.most_brewed_coffee,
        description: "The coffee that made frequent appearances this year. A testament to finding that perfect match."
      },
      most_used_profile: {
        title: "Most Used Profile",
        stat: yearly_brew.most_used_profile,
        description: "The recipe that delivered consistently great results. A reliable companion in the coffee journey."
      },
      best_rated_coffee: {
        title: "Best Rated Coffee",
        stat: yearly_brew.best_rated_coffee
      },
      weekly_rhythm: {
        title: "Weekly Rhythm",
        stat: yearly_brew.shots_per_day_of_week.to_json,
        description: "Coffee brewing patterns throughout the week. A glimpse into when the brewing magic happens most."
      },
      monthly_enjoyment: {
        title: "Monthly Enjoyment",
        stat: yearly_brew.monthly_enjoyments.to_json,
        description: "Coffee satisfaction levels tracked month by month."
      },
      busiest_month: {
        title: "Busiest Month",
        stat: yearly_brew.month_with_most_shots,
        description: "Peak coffee brewing activity. When the coffee scale barely got a break!"
      },
      most_active_day: {
        title: "Busiest Day",
        stat: yearly_brew.day_with_most_shots,
        description: "The weekday when coffee flows most freely. Looks like someone's got a favorite brewing day!"
      },
      coffee_brewed: {
        title: "Coffee Brewed",
        stat: "#{yearly_brew.amount_brewed} kg",
        description: "Total amount of delicious coffee brewed this year. Impressive!"
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
