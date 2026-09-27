class Shot
  module GrindSuggestable
    extend ActiveSupport::Concern

    DIAL_IN_ATTRIBUTES = %w[bean_weight drink_weight duration espresso_enjoyment grinder_model grinder_setting profile_title coffee_bag_id bean_brand bean_type].freeze
    HISTORY_LIMIT = 5
    REGRESSION_LIMIT = 20
    MIN_DIRECTION_PROBABILITY = 0.6
    DIRECTION_LEVELS = {"finer" => [0, 1, 2], "keep" => [3], "coarser" => [4, 5, 6]}.freeze
    ADJUSTMENT_LABELS = ["Much finer", "Finer", "Slightly finer", "Keep the grind", "Slightly coarser", "Coarser", "Much coarser"].freeze
    QUESTIONS = {
      adjustment: {
        type: "score",
        instructions: "How should the user change grind size for their next shot of this coffee on this profile? Judge `shot` by its taste notes, enjoyment, time and ratio, and compare it with the user's earlier shots in `history`.",
        criteria: [
          "Grind much finer: the shot ran far too fast, gushed, or tasted very sour, thin or watery",
          "Grind finer: the shot ran clearly too fast or tasted sour and under-extracted",
          "Grind slightly finer: the shot ran a little fast or tasted slightly sharp or sour, otherwise close",
          "Keep the same grind: time and taste are good, or the problems are not caused by grind size",
          "Grind slightly coarser: the shot ran a little slow or tasted slightly bitter or harsh, otherwise close",
          "Grind coarser: the shot ran clearly too slow or tasted bitter, astringent and over-extracted",
          "Grind much coarser: the shot choked, barely dripped, or tasted very bitter, ashy or burnt"
        ]
      },
      puck_issue: {
        type: "noul",
        instructions: "Does `shot` indicate channeling, spritzing, or uneven puck preparation?"
      }
    }.freeze

    included do
      after_commit :suggest_grind_later, on: %i[create update], if: :grind_suggestion_needed?
    end

    def suggest_grind_later
      GrindSuggestionJob.perform_later(self)
    end

    def suggest_grind_now
      reference = reference_target
      response = TypeSafe.new.system_one(state: grind_suggestion_state(reference), questions: QUESTIONS)
      update_column(:grind_suggestion, grind_suggestion_from(response, reference)) # rubocop:disable Rails/SkipsModelValidations
      broadcast_replace_to [self, :grind_suggestion], target: ActionView::RecordIdentifier.dom_id(self, :grind_suggestion), partial: "shots/grind_suggestion", locals: {shot: self}
    end

    private

    def grind_suggestion_needed?
      user&.admin? && duration.to_f.positive? && (previously_new_record? || saved_changes.keys.intersect?(DIAL_IN_ATTRIBUTES) || espresso_notes_saved?)
    end

    def espresso_notes_saved?
      association(:rich_text_espresso_notes).loaded? && rich_text_espresso_notes&.saved_change_to_body?
    end

    def grind_suggestion_state(reference)
      {
        shot: dial_in_summary(self, notes_limit: 1000).merge(comparison_with(reference)),
        history: grind_history
      }.compact_blank
    end

    def grind_history
      {
        same_coffee: same_coffee_shots,
        same_profile: (prior_shots.where(profile_title:) if profile_title.present?),
        same_grind: (prior_shots.where(grinder_model:, grinder_setting:) if grinder_setting.present?)
      }.compact.transform_values do |shots|
        shots.by_start_time.with_rich_text_espresso_notes.limit(HISTORY_LIMIT).map { dial_in_summary(it, notes_limit: 200) }
      end.compact_blank
    end

    def dial_in_summary(shot, notes_limit:)
      ratio = shot.weight_ratio
      {
        coffee: [shot.bean_brand, shot.bean_type].compact_blank.join(" "),
        roast_level: shot.roast_level,
        profile: shot.profile_title,
        grinder: shot.grinder_model,
        grind_setting: shot.grinder_setting,
        dose_g: (shot.bean_weight_f if shot.bean_weight_f.positive?),
        yield_g: (shot.drink_weight_f if shot.drink_weight_f.positive?),
        ratio: ("1:#{ratio.round(1)}" if ratio.finite? && ratio.positive?),
        time_s: shot.duration&.round,
        enjoyment: ("#{shot.espresso_enjoyment}/100" if shot.espresso_enjoyment.to_i.positive?),
        taste_notes: shot.espresso_notes.to_plain_text.squish.truncate(notes_limit)
      }.compact_blank
    end

    def comparison_with(reference)
      return {} unless reference

      comparison = {
        reference: reference[:description],
        time: relative_label(duration, reference[:duration], "shorter", "longer"),
        ratio: relative_label(weight_ratio, reference[:ratio], "lower", "higher")
      }
      {compared_with_reference: comparison.compact}
    end

    def relative_label(value, reference, lower, higher)
      return unless [value, reference].all? { it.to_f.finite? && it.to_f.positive? }

      change = (value - reference) / reference
      if change < -0.25
        "much #{lower}"
      elsif change < -0.1
        lower
      elsif change <= 0.1
        "about the same"
      elsif change <= 0.25
        higher
      else
        "much #{higher}"
      end
    end

    def grind_suggestion_from(response, reference)
      probabilities = response.dig("answers", "adjustment", "probabilities").transform_keys(&:to_i)
      direction, probability = DIRECTION_LEVELS.transform_values { |levels| levels.sum { probabilities.fetch(it, 0) } }.max_by(&:last)
      suggestion = {
        "probability" => probability.round(2),
        "puck_issue" => response.dig("answers", "puck_issue", "noul"),
        "model" => response["model"],
        "generated_at" => Time.current.iso8601
      }

      if probability < MIN_DIRECTION_PROBABILITY
        suggestion.merge("label" => "Not sure")
      else
        level = DIRECTION_LEVELS[direction].max_by { probabilities.fetch(it, 0) }
        suggestion.merge("direction" => direction, "label" => ADJUSTMENT_LABELS[level], "setting_range" => setting_range(direction, reference))
      end
    end

    # ponytail: straight-line fit of time vs setting, no outlier rejection; swap for a robust fit if ranges look noisy
    def setting_range(direction, reference)
      current = numeric_setting(grinder_setting)
      shots = same_coffee_shots
      return if direction == "keep" || current.nil? || grinder_model.blank? || reference.nil? || shots.nil?

      rows = shots.where(profile_title:, grinder_model:).where(duration: 0.1..).by_start_time.limit(REGRESSION_LIMIT).pluck(:grinder_setting, :duration)
      rows << [grinder_setting, duration]
      points = rows.filter_map { |setting, time| [numeric_setting(setting), time] if numeric_setting(setting) }
      return if points.size < 3 || points.map(&:first).uniq.size < 2

      slope = time_per_setting(points)
      return if slope.zero?

      target = current + ((reference[:duration] - duration) / slope)
      decimals = rows.map { |setting, _| setting.to_s[/[.,](\d+)/, 1].to_s.size }.max
      resolution = 10.0**-decimals
      coarser = (target > current) == slope.negative?
      return if (target - current).abs < resolution || coarser != (direction == "coarser")

      spread = [(target - current).abs * 0.25, resolution].max
      [target - spread, target + spread].map { [it, 0].max.round(decimals).to_s }
    end

    def time_per_setting(points)
      settings, times = points.transpose
      setting_mean = settings.sum / settings.size
      time_mean = times.sum / times.size
      points.sum { |setting, time| (setting - setting_mean) * (time - time_mean) } / settings.sum { (it - setting_mean)**2 }
    end

    def numeric_setting(setting)
      normalized = setting.to_s.strip.tr(",", ".")
      normalized.to_f if normalized.match?(/\A\d+(\.\d+)?\z/)
    end

    def reference_target
      return if profile_title.blank?

      best = same_coffee_shots&.where(profile_title:, espresso_enjoyment: 1.., duration: 0.1..)&.order(espresso_enjoyment: :desc, start_time: :desc)&.first
      if best
        {duration: best.duration, ratio: best.weight_ratio, description: "best-rated earlier shot of this coffee on this profile (#{best.espresso_enjoyment}/100)"} if best.espresso_enjoyment > espresso_enjoyment.to_i
      else
        typical_target
      end
    end

    def typical_target
      shots = prior_shots.where(profile_title:, duration: 0.1..).by_start_time.limit(REGRESSION_LIMIT).to_a
      return if shots.size < 3

      ratios = shots.map(&:weight_ratio).select { it.finite? && it.positive? }
      {duration: median(shots.map(&:duration)), ratio: (median(ratios) if ratios.any?), description: "user's typical earlier shot on this profile"}
    end

    def median(values)
      sorted = values.sort
      (sorted[(sorted.size - 1) / 2] + sorted[sorted.size / 2]) / 2.0
    end

    def same_coffee_shots
      if coffee_bag_id
        prior_shots.where(coffee_bag_id:)
      elsif bean_type.present?
        prior_shots.where(bean_brand:, bean_type:)
      end
    end

    def prior_shots
      Shot.where(user_id:).where(start_time: ...start_time).where.not(id:)
    end
  end
end
