# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    skip_before_action :verify_current_user, except: %i[upload]

    def index
      limit = params[:limit].presence.to_i
      limit = 10 if limit.zero?
      limit = 100 if limit.to_i > 100

      shots = current_user.present? ? current_user.shots : Shot.visible
      shots = shots.offset(params[:offset]).by_start_time.take(limit.to_i).pluck(:id, :start_time)
      render json: shots.map { |id, time| {clock: time.to_i, id: id} }
    end

    def download
      with_shot do |shot|
        render json: shot_json(shot)
      end
    end

    def profile
      with_shot do |shot|
        send_file shot.tcl_profile, filename: "#{shot.profile_title} from Visualizer.tcl", type: "application/x-tcl", disposition: "attachment"
      end
    end

    def shared
      shot = SharedShot.find_by(code: params[:code].upcase)&.shot
      if shot
        render json: shot_json(shot)
      else
        render json: {error: "Shared shot not found"}, status: :not_found
      end
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

    def with_shot
      shot = Shot.find_by(id: params[:shot_id])
      if shot
        yield(shot)
      else
        render json: {error: "Shot not found"}, status: :not_found
      end
    end

    def shot_json(shot)
      return {} unless shot

      allowed_attrs = %w[profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes]
      allowed_attrs += %w[start_time] unless shot.user&.hide_shot_times
      allowed_attrs += %w[timeframe data] if params[:essentials].blank?
      json = shot.attributes.slice(*allowed_attrs)
      json[:image_preview] = shot.screenshot_url if shot.screenshot?
      json[:profile_url] = api_shot_profile_url(shot) if shot.tcl_profile_fields.present?
      json
    end
  end
end
