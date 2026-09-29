class CoffeeBag
  module GrindSuggestable
    extend ActiveSupport::Concern

    PROFILE_LIMIT = 3
    CANDIDATE_LIMIT = 10
    SUMMARY_ATTRIBUTES = %w[roast_level country region variety elevation processing tasting_notes].freeze
    MIN_DIRECTION_PROBABILITY = 0.6
    DIRECTION_LEVELS = {"finer" => [0, 1], "same" => [2], "coarser" => [3, 4]}.freeze
    RELATIVE_LABELS = ["Much finer than", "Slightly finer than", "Same as", "Slightly coarser than", "Much coarser than"].freeze
    RELATIVE_CRITERIA = [
      "Grind much finer: `new_coffee` is clearly harder to extract, e.g. a much lighter roast or much denser, high-grown washed beans",
      "Grind slightly finer: `new_coffee` is a bit lighter roasted or a bit denser",
      "Same grind: similar roast level, processing, origin and altitude",
      "Grind slightly coarser: `new_coffee` is a bit darker roasted, softer, lower-grown, or natural or anaerobic processed",
      "Grind much coarser: `new_coffee` is clearly easier to extract, e.g. a much darker roast"
    ].freeze

    included do
      performs :suggest_grind
      after_commit :suggest_grind_later, on: %i[create update], if: :grind_suggestion_needed?
    end

    def suggest_grind
      profiles = recent_profiles
      shots_by_profile = dialed_in_shots(profiles).group_by { [it.profile_title, it.grinder_model] }
      own = profiles.index_with { |profile| shots_by_profile[profile.values].to_a.find { it.coffee_bag_id == id } }
      candidates = profiles.reject { own[it] }.index_with { candidate_shots(shots_by_profile[it.values].to_a) }
      bags = candidates.values.flat_map { it.map(&:coffee_bag) }.uniq
      answers = bags.any? ? TypeSafe.new.system_one(state: similarity_state(bags), questions: similarity_questions(bags))["answers"] : {}

      suggestions = profiles.filter_map do |profile|
        if own[profile]
          from_own_shot(profile, own[profile])
        elsif candidates[profile].any?
          from_similar_bag(profile, candidates[profile], bags, answers)
        end
      end
      update_columns(grind_suggestion: suggestions, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      broadcast_replace_to [user, :coffee_bag_grind_suggestions], target: ActionView::RecordIdentifier.dom_id(self, :grind_suggestion), partial: "coffee_bags/grind_suggestion", locals: {coffee_bag: self}
    end

    private

    def grind_suggestion_needed?
      user&.admin? && (previously_new_record? || saved_changes.keys.intersect?(SUMMARY_ATTRIBUTES + %w[name roaster_id]))
    end

    def recent_profiles
      latest = user.shots.where.not(profile_title: [nil, ""]).select("DISTINCT ON (profile_title) profile_title, grinder_model, start_time").order(:profile_title, start_time: :desc)
      Shot.from(latest, :shots).order(start_time: :desc).limit(PROFILE_LIMIT).map { {profile_title: it.profile_title, grinder_model: it.grinder_model} }
    end

    def dialed_in_shots(profiles)
      user.shots.where(profile_title: profiles.pluck(:profile_title), grinder_model: profiles.pluck(:grinder_model).uniq)
        .where.not(grinder_setting: [nil, ""]).where.not(coffee_bag_id: nil)
        .select(:id, :coffee_bag_id, :profile_title, :grinder_model, :grinder_setting, :espresso_enjoyment, :start_time, :grind_suggestion)
        .includes(coffee_bag: :roaster).by_start_time
    end

    def candidate_shots(shots)
      shots.reject { it.coffee_bag_id == id }.group_by(&:coffee_bag_id).first(CANDIDATE_LIMIT).map do |_, bag_shots|
        bag_shots.select { it.espresso_enjoyment.to_i.positive? }.max_by { [it.espresso_enjoyment, it.start_time] } || bag_shots.first
      end
    end

    def similarity_state(bags)
      {new_coffee: grind_summary(self), earlier_coffees: bags.each_with_index.to_h { |bag, i| ["coffee_#{i}", grind_summary(bag)] }}
    end

    def grind_summary(bag)
      {name: bag.name, roaster: bag.roaster.name, **bag.attributes.slice(*SUMMARY_ATTRIBUTES).compact_blank}
    end

    def similarity_questions(bags)
      questions = bags.each_index.to_h do |i|
        [:"relative_#{i}", {type: "score", instructions: "Compared with `earlier_coffees.coffee_#{i}`, how should `new_coffee` be ground for espresso to extract equally well?", criteria: RELATIVE_CRITERIA}]
      end
      if bags.many?
        questions[:similar] = {
          type: "choice",
          instructions: "Which coffee in `earlier_coffees` is most similar to `new_coffee` in roast level, processing, origin, altitude and variety?",
          criteria: bags.each_index.to_h { ["coffee_#{it}", "`earlier_coffees.coffee_#{it}`"] }
        }
      end
      questions
    end

    def from_own_shot(profile, shot)
      suggestion = shot.grind_suggestion.to_h
      base_suggestion(profile, shot).merge("label" => suggestion["label"], "setting_range" => suggestion["setting_range"])
    end

    def from_similar_bag(profile, shots, bags, answers)
      similarity = answers.dig("similar", "probabilities").to_h
      shot = shots.max_by { similarity.fetch("coffee_#{bags.index(it.coffee_bag)}", 0) }
      probabilities = answers.dig("relative_#{bags.index(shot.coffee_bag)}", "probabilities").to_h.transform_keys(&:to_i)
      direction, probability = DIRECTION_LEVELS.transform_values { |levels| levels.sum { probabilities.fetch(it, 0) } }.max_by(&:last)
      level = DIRECTION_LEVELS[direction].max_by { probabilities.fetch(it, 0) }
      base_suggestion(profile, shot).merge("based_on" => shot.coffee_bag.name, "relation" => (RELATIVE_LABELS[level] if probability >= MIN_DIRECTION_PROBABILITY))
    end

    def base_suggestion(profile, shot)
      {"profile" => profile[:profile_title], "grinder" => profile[:grinder_model], "setting" => shot.grinder_setting}
    end
  end
end
