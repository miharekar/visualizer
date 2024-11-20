class ShotChart
  class ParsedShot
    prepend MemoWise
    include Bsearch

    DATA_LABELS_MAP = {"weight" => "espresso_weight", "waterFlow" => "espresso_flow", "realtimeFlow" => "espresso_flow_weight", "pressureFlow" => "espresso_pressure", "temperatureFlow" => "espresso_temperature_mix"}.freeze
    DATA_VALUES_MAP = {"weight" => "actual_weight", "waterFlow" => "value", "realtimeFlow" => "flow_value", "pressureFlow" => "actual_pressure", "temperatureFlow" => "actual_temperature"}.freeze

    attr_reader :shot, :timeframe, :data

    def initialize(shot)
      @shot = shot

      if shot.information.chart_data?
        @timeframe = shot.information.timeframe
        @data = shot.information.data
      else
        parse_brew_flow
      end
    end

    memo_wise def fahrenheit?
      shot.information.extra["enable_fahrenheit"].to_i == 1
    end

    memo_wise def stage_indices
      has_state_data = data.key?("espresso_state_change") && data["espresso_state_change"].present?
      has_state_data ? stages_from_state_change : detect_stages_from_data
    end

    private

    def parse_brew_flow
      brew_flow = shot.information.brewdata.try(:[], "brewFlow")
      return if brew_flow.blank?

      @timeframe = []
      relevant_keys = brew_flow.keys.select { |k| brew_flow[k].size > 1 } & DATA_LABELS_MAP.keys
      @data = DATA_LABELS_MAP.values_at(*relevant_keys).index_with { |_label| [] }
      brew_flow.each_value do |data|
        data.each do |d|
          d["unix_timestamp"] = Time.strptime(d["timestamp"], "%H:%M:%S.%L").to_f
        end
      end
      longest = brew_flow.keys.max_by { |l| brew_flow[l].size }
      start = brew_flow[longest].first["unix_timestamp"].to_f
      brew_flow[longest].each do |d|
        @timeframe << (d["unix_timestamp"] - start).round(4).to_s
        relevant_keys.each do |key|
          closest = closest_bsearch(brew_flow[key], d["unix_timestamp"], key: "unix_timestamp")
          value = closest[DATA_VALUES_MAP[key]]
          @data[DATA_LABELS_MAP[key]] << (value&.positive? ? value : 0)
        end
      end
    end

    def stages_from_state_change
      indices = []
      current = data["espresso_state_change"].find { |s| !s.to_i.zero? }
      data["espresso_state_change"].each.with_index do |s, i|
        next if s.to_i.zero? || s == current

        indices << i
        current = s
      end
      indices
    end

    def detect_stages_from_data
      indices = []
      diff_threshold = 0.05

      loop do
        indices = []
        data.select { |label, _| label.end_with?("_goal") }.each_value do |d|
          next if d.blank?

          d = d.map(&:to_f)
          d.each.with_index do |a, i|
            next if i < 5

            b = d[i - 1]
            c = d[i - 2]
            diff2 = ((a - b) - (b - c))
            indices << i if diff2.abs > diff_threshold
          end
        end

        break if indices.size <= shot.duration / 2

        diff_threshold += 0.05
      end

      if indices.any?
        indices = indices.sort.uniq
        selected = [indices.first]
        indices.each do |index|
          selected << index if (index - selected.last) > 5
        end
      end
      selected
    end
  end
end
