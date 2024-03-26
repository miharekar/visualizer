module ShotChart::Process
  DATA_LABELS_TO_IGNORE = %w[espresso_resistance espresso_resistance_weight espresso_state_change].freeze

  def process_data(parsed_shot, label_suffix: nil)
    timeframe = parsed_shot.timeframe
    timeframe_count = timeframe.count
    timeframe_last = timeframe.last.to_f
    timeframe_diff = (timeframe_last + timeframe.first.to_f) / timeframe.count.to_f
    to_fahrenheit = user&.wants_fahrenheit?
    parsed_shot.data.filter_map do |label, data|
      next if DATA_LABELS_TO_IGNORE.include?(label)

      times10 = label == "espresso_water_dispensed"
      temperature_label = label.include?("temperature")
      data = data.map.with_index do |v, i|
        t = (i < timeframe_count) ? timeframe[i] : timeframe_last + ((i - timeframe_count + 1) * timeframe_diff)
        v = v.to_f
        v *= 10 if times10
        if temperature_label
          if to_fahrenheit && !parsed_shot.fahrenheit?
            v = (v * 9 / 5) + 32
          elsif !to_fahrenheit && parsed_shot.fahrenheit?
            v = (v - 32) * 5 / 9
          end
        end
        v = nil if v.negative?
        [t.to_f * 1000, v]
      end
      [[label, label_suffix].join, data]
    end.to_h
  end
end
