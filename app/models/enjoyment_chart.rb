class EnjoymentChart
  include Rails.application.routes.url_helpers
  include ColorHelper

  attr_reader :shots

  def initialize(shots)
    @shots = shots
  end

  def chart
    shots.map do |shot|
      {
        x: shot.start_time.to_i * 1000,
        y: shot.espresso_enjoyment,
        color: enjoyment_hex(shot.espresso_enjoyment),
        url: shot_path(shot),
        title: "#{shot.espresso_enjoyment}: #{shot.profile_title} with #{shot.bean_brand} #{shot.bean_type}"
      }
    end.reverse
  end
end
