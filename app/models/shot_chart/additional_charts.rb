module ShotChart::AdditionalCharts
  MAX_RESISTANCE_VALUE = 19
  MIN_CONDUCTANCE_DIFF_VALUE = -5
  GAUSSIAN_MULTIPLIERS = [0.048297, 0.08393, 0.124548, 0.157829, 0.170793, 0.157829, 0.124548, 0.08393, 0.048297].freeze

  def resistance_chart(pressure_data, flow_data)
    pressure_data.map.with_index do |(t, v), i|
      f = flow_data[i]&.second.to_f
      if f&.zero?
        v = nil
      else
        r = v.to_f / (f**2)
        v = (r > MAX_RESISTANCE_VALUE) ? nil : r
      end
      [t, v]
    end
  end

  def conductance_chart(pressure_data, flow_data)
    pressure_data.map.with_index do |(t, v), i|
      f = flow_data[i]&.second.to_f
      if v&.zero?
        v = nil
      else
        c = (f**2) / v.to_f
        v = (c > MAX_RESISTANCE_VALUE) ? nil : c
      end
      [t, v]
    end
  end

  def conductance_derivative_chart(conductance_data)
    derivative = []
    conductance_data.each_cons(2) do |(t1, v1), (t2, v2)|
      v = if v1.nil? || v2.nil?
        nil
      else
        ((v2 - v1) / ((t2 - t1) / 1000)) * 10
      end
      derivative << [t1, v]
    end

    smoothed = []
    4.times do
      derivative << [nil, nil]
      smoothed << [nil, nil]
    end

    derivative.each_cons(9) do |data|
      values = data.map(&:last)
      value = values.zip(GAUSSIAN_MULTIPLIERS).sum { |v, m| v.to_f * m }
      value = nil if value > MAX_RESISTANCE_VALUE || value < MIN_CONDUCTANCE_DIFF_VALUE
      smoothed << [data[4].first, value]
    end

    smoothed.reject { |k, _| k.nil? }
  end
end
