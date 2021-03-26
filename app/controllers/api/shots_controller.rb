# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    include CloudinaryHelper

    skip_before_action :verify_current_user, only: [:download]

    def index
      limit = params[:limit].presence || 10
      shots = current_user.shots.by_start_time.first(limit.to_i).pluck(:id, :start_time)

      render json: shots.map { |id, time| {clock: time.to_i, id: id} }
    end

    def download
      shot = current_user ? Shot.where(user_id: current_user.id) : Shot.visible
      shot = shot.find_by(id: params[:shot_id])

      if shot
        allowed_attrs = %w[start_time profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes]
        allowed_attrs += %w[timeframe data] if params[:essentials].blank?
        json = shot.attributes.slice(*allowed_attrs)
        json = json.merge(image_preview: cl_image_path(shot.cloudinary_id)) if shot.cloudinary_id.present?
        render json: json
      else
        head :unprocessable_entity
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
  end
end
