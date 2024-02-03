# frozen_string_literal: true

module ShotInformation::LiveParser
  DATA_LABELS_MAP = {"weight" => "espresso_weight", "waterFlow" => "espresso_flow", "realtimeFlow" => "espresso_flow_weight", "pressureFlow" => "espresso_pressure", "temperatureFlow" => "espresso_temperature_mix"}.freeze
  DATA_VALUES_MAP = {"weight" => "actual_weight", "waterFlow" => "value", "realtimeFlow" => "flow_value", "pressureFlow" => "actual_pressure", "temperatureFlow" => "actual_temperature"}.freeze

  prepend MemoWise
  include Bsearch

  memo_wise def data
    data = attributes["data"]
    return data if data.present?

    parse_brew_flow if should_live_parse?
    @parsed_data
  end

  memo_wise def timeframe
    @parsed_timeframe.presence || attributes["timeframe"]
  end

  memo_wise def brewflow
    brewdata.try(:[], "brewFlow")
  end

  def should_live_parse?
    attributes["data"].blank? && brewflow.present?
  end

  def parse_brew_flow
    @parsed_timeframe = []
    relevant_keys = brewdata["brewFlow"].keys.select { |k| brewdata["brewFlow"][k].size > 1 }
    @parsed_data = DATA_LABELS_MAP.values_at(*relevant_keys).index_with { |label| [] }
    brewdata["brewFlow"].each do |label, data|
      data.each do |d|
        d["unix_timestamp"] = Time.strptime(d["timestamp"], "%H:%M:%S.%L").to_f
      end
    end
    longest = brewdata["brewFlow"].keys.max_by { |l| brewdata["brewFlow"][l].size }
    start = brewdata["brewFlow"][longest].first["unix_timestamp"].to_f
    brewdata["brewFlow"][longest].each do |d|
      @parsed_timeframe << (d["unix_timestamp"] - start).round(4).to_s
      relevant_keys.each do |key|
        closest = closest_bsearch(brewdata["brewFlow"][key], d["unix_timestamp"], key: "unix_timestamp")
        value = closest[DATA_VALUES_MAP[key]]
        @parsed_data[DATA_LABELS_MAP[key]] << (value&.positive? ? value : 0)
      end
    end
  end
end
