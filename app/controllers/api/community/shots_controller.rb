module Api
  module Community
    # Read-only community-shot search by bean (and optionally profile/grinder/user),
    # giving the API the same visibility rules as the Community page. A bean, profile,
    # grinder or user filter is required, so it can't be used as a bulk dump.
    class ShotsController < Api::BaseController
      include Filterable

      LIST_ATTRIBUTES = [*Shot::LIST_ATTRIBUTES, :roast_level, :canonical_coffee_bag_id].freeze
      REQUIRED_FILTERS = %i[bean_brand bean_type canonical_coffee_bag_id profile_title grinder_model user_id].freeze
      # Exact-match uuid columns: a non-uuid value would cast to NULL and silently
      # become `WHERE col IS NULL`, turning the required-filter gate into a bulk dump.
      UUID_FILTERS = %i[canonical_coffee_bag_id user_id].freeze

      before_action :ignore_token_without_read_scope

      def index
        if REQUIRED_FILTERS.none? { params[it].present? }
          render json: {error: "Provide at least one filter"}, status: :bad_request
        elsif (bad = UUID_FILTERS.find { params[it].present? && !params[it].to_s.match?(ApplicationRecord::UUID_PATTERN) })
          render json: {error: "#{bad} must be a valid UUID"}, status: :bad_request
        else
          shots, paging = paginate(community_shots.select(LIST_ATTRIBUTES).includes(:user), with_counts: false)
          render json: {data: shots.map { shot_json(it) }, paging:, user_id: Current.user&.id}
        end
      end

      private

      def community_shots
        @shots = Shot.visible_or_owned_by_id(Current.user&.id)
        apply_standard_filters_to_shots(indexed_only: true)
        @shots = @shots.where(canonical_coffee_bag_id: params[:canonical_coffee_bag_id]) if params[:canonical_coffee_bag_id].present?
        @shots = @shots.where(user_id: params[:user_id]) if params[:user_id].present?
        @shots = @shots.non_premium unless Current.user&.premium?
        @shots.by_start_time
      end

      def shot_json(shot)
        json = shot.attributes.slice(*LIST_ATTRIBUTES.map(&:to_s))
        # Times go out as Unix seconds, matching the shot list API's `clock`/`updated_at`.
        json["start_time"] = shot.start_time.to_i
        json["updated_at"] = shot.updated_at.to_i
        json.except!("start_time", "updated_at") if shot.user&.hide_shot_times? && Current.user != shot.user
        json["user_name"] = shot.user.display_name if shot.user&.public?
        json
      end
    end
  end
end
