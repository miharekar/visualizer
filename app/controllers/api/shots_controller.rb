# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    extend Memoist
    include Pagy::Backend

    skip_before_action :verify_current_user, except: %i[upload]

    def index
      items = params[:items].presence.to_i
      items = 10 if items.zero?
      items = 100 if items.to_i > 100

      shots = current_user.present? ? current_user.shots : Shot.visible
      shots = shots.by_start_time.select(:id, :start_time, :user_id)

      pagy, shots = pagy(shots, items: items)
      data = shots.map { |s| {clock: s.start_time.to_i, id: s.id} }
      render json: {data: data, paging: pagy_metadata(pagy)}
    rescue Pagy::VariableError
      render json: {error: "Could not paginate"}, status: :unprocessable_entity
    end

    def download
      with_shot do |shot|
        render json: shot_json(shot, with_data: !params[:essentials].presence)
      end
    end

    def profile
      with_shot do |shot|
        if shot.tcl_profile_fields.present?
          send_file shot.tcl_profile, filename: "#{shot.profile_title} from Visualizer.tcl", type: "application/x-tcl", disposition: "attachment"
        else
          render json: {error: "Shot does not have a profile"}, status: :unprocessable_entity
        end
      end
    end

    def shared
      if current_user.present?
        distinct_shots = current_user.shared_shots.distinct.pluck(:shot_id)
        render json: Shot.where(id: distinct_shots).map { |s| shot_json(s) }
      else
        shared = SharedShot.find_by(code: params[:code].to_s.upcase)
        if shared
          render json: shot_json(shared.shot)
        else
          render json: {error: "Shared shot not found"}, status: :not_found
        end
      end
    end

    def upload
      shot = Shot.from_file(current_user, params[:file])
      if shot&.save
        render json: {id: shot.id}
      else
        render json: {error: "Could not parse the provided file"}, status: :unprocessable_entity
      end
    end

    private

    def with_shot
      shot = Shot.find_by(id: params[:shot_id])
      if shot
        yield(shot)
      else
        render json: {error: "Shot not found"}, status: :not_found
      end
    end

    def shot_json(shot, with_data: false)
      return {} unless shot

      allowed_attrs = %w[id profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes]
      allowed_attrs += %w[start_time] unless shot.user&.hide_shot_times
      allowed_attrs += %w[timeframe data] if with_data
      json = shot.attributes.slice(*allowed_attrs)
      json[:image_preview] = shot.screenshot_url if shot.screenshot?
      json[:profile_url] = api_shot_profile_url(shot) if shot.tcl_profile_fields.present?
      json
    end
  end
end
