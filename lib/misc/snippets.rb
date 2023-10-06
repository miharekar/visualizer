# frozen_string_literal: true

def top_profiles(from:)
  profiles = Shot.where(created_at: from..).pluck(:profile_title)
  total = profiles.size.to_f
  profiles.map { |p| p.to_s.sub("Visualizer/", "") }.tally.sort_by { |_p, c| c }.last(20).reverse.to_h.transform_values { |c| (c / total * 100).round(2) }
end

def top_skins
  relevant = Shot.joins(:information).where(created_at: 2.months.ago..).pluck(:extra, :user_id)
  users_with_skins = relevant.map { |e, u| [u, e["skin"]] }.uniq.select { |_, s| s.present? }
  total_users = users_with_skins.uniq { |us| us[0] }.size.to_f
  users_with_skins.pluck(1).tally.sort_by { |_s, c| c }.reverse.to_h.transform_values { |c| (c / total_users * 100).round(2) }
end

def shots_brewed_by_time_of_day
  @brewed_chart = [{
    name: "Shots brewed by time of day",
    data: Shot.select(:start_time).map { |s| (s.start_time.hour * 60) + s.start_time.min }.tally.map { |minute, count| [Time.at(minute * 60).to_i * 1000, count] }.sort
  }]
end

top_profiles(from: "1.1.2000".to_date)
top_profiles(from: 1.month.ago)
top_skins
