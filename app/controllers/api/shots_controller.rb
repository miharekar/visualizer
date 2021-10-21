# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    skip_before_action :verify_current_user, only: %i[download shared profile]

    def index
      limit = params[:limit].presence || 10
      shots = current_user.shots.by_start_time.first(limit.to_i).pluck(:id, :start_time)

      render json: shots.map { |id, time| {clock: time.to_i, id: id} }
    end

    def download
      shot = Shot.find_by(id: params[:shot_id])
      render json: shot_json(shot)
    end

    def shared
      shot = SharedShot.find_by(code: params[:code].upcase)&.shot
      render json: shot_json(shot)
    end

    def profile
      shot = Shot.find_by(id: params[:shot_id])
      send_file shot.tcl_profile, filename: "#{shot.profile_title} from Visualizer.tcl", type: "application/x-tcl", disposition: "attachment"
    end

    def upload
      shot = Shot.from_file(current_user, params[:file])
      if shot&.save
        render json: {id: shot.id}
      else
        head :unprocessable_entity
      end
    end

    private

    def shot_json(shot)
      return {} unless shot

      allowed_attrs = %w[start_time profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes]
      allowed_attrs += %w[timeframe data] if params[:essentials].blank?
      json = shot.attributes.slice(*allowed_attrs)
      json[:image_preview] = shot.screenshot_url if shot.screenshot?
      json[:profile_url] = api_shot_profile_url(shot) if shot.tcl_profile_fields.present?
      json
    end
  end
end
