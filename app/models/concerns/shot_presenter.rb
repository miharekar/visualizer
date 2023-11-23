# frozen_string_literal: true

module ShotPresenter
  SCREENSHOTS_URL = "https://visualizer-coffee-shots.s3.eu-central-1.amazonaws.com"

  def screenshot_url
    "#{SCREENSHOTS_URL}/screenshots/#{id}.png" if screenshot?
  end

  %i[bean_weight drink_weight drink_tds drink_ey].each do |attribute|
    define_method("#{attribute}_f") do
      public_send(attribute).to_f
    end
  end

  def weight_ratio
    drink_weight_f / bean_weight_f
  end
end
