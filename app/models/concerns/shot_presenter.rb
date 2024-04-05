module ShotPresenter
  SCREENSHOTS_URL = "https://visualizer-coffee-shots.s3.eu-central-1.amazonaws.com"

  def screenshot_url
    "#{SCREENSHOTS_URL}/screenshots/#{id}.png" if screenshot?
  end

  %i[bean_weight drink_weight drink_tds drink_ey].each do |attribute|
    define_method(:"#{attribute}_f") do
      public_send(attribute).to_f
    end
  end

  def weight_ratio
    drink_weight_f / bean_weight_f
  end

  def weight_and_ratio_info
    weight_parts = []
    weight_parts << "#{bean_weight} g" if bean_weight_f > 0
    weight_parts << "#{drink_weight} g" if drink_weight_f > 0
    weight_string = weight_parts.join(" : ")
    ratio_string = "(1:#{weight_ratio.round(1)})" if bean_weight_f > 0 && drink_weight_f > 0 && weight_ratio > 0
    [weight_string, ratio_string].compact.join(" ")
  end

  def bean_brand
    coffee_bag ? coffee_bag.roaster.name : super
  end

  def bean_type
    coffee_bag ? coffee_bag.name : super
  end

  def roast_level
    coffee_bag ? coffee_bag.roast_level : super
  end

  def roast_date
    coffee_bag ? coffee_bag.roast_date&.to_fs(:iso8601) : super
  end
end
