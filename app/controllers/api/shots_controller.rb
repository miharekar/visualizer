module Api
  class ShotsController < Api::BaseController
    include Pagy::Backend

    before_action :verify_upload_access, only: %i[upload]
    before_action :verify_write_access, only: %i[destroy]

    def index
      limit = params[:items].presence.to_i
      limit = 10 if limit.zero?
      limit = 100 if limit.to_i > 100

      shots = Current.user.present? ? Current.user.shots : Shot.visible
      shots = shots.non_premium unless Current.user&.premium?
      shots = shots.by_start_time.select(:id, :start_time, :user_id)

      pagy, shots = pagy(shots, limit:)
      data = shots.map { |s| {clock: s.start_time.to_i, id: s.id} }
      render json: {data:, paging: pagy_metadata(pagy)}
    rescue Pagy::VariableError
      render json: {error: "Could not paginate"}, status: :unprocessable_entity
    end

    def show
      with_shot do |shot|
        render json: shot.to_api_json(with_data: !params[:essentials].presence)
      end
    end
    alias_method :download, :show

    def profile
      with_shot do |shot|
        if params[:format] == "csv"
          send_data shot.information&.csv_profile, filename: "#{shot.profile_title} from Visualizer.csv", type: "text/csv", disposition: "attachment"
        elsif params[:format] == "json" && shot.information&.json_profile_fields.present?
          render json: shot.information&.json_profile
        elsif shot.information&.tcl_profile_fields.present?
          send_data shot.information.tcl_profile, filename: "#{shot.profile_title} from Visualizer.tcl", type: "application/x-tcl", disposition: "attachment"
        else
          render json: {error: "Shot does not have a profile"}, status: :unprocessable_entity
        end
      end
    end

    def shared
      if Current.user.present?
        distinct_shots = Current.user.shared_shots.distinct.pluck(:shot_id)
        render json: Shot.where(id: distinct_shots).map { |s| s.to_api_json(with_data: params[:with_data].presence) }
      else
        shared = SharedShot.find_by(code: params[:code].to_s.upcase)
        if shared
          render json: shared.shot.to_api_json(with_data: params[:with_data].presence)
        else
          render json: {error: "Shared shot not found"}, status: :not_found
        end
      end
    end

    def upload
      shot = Shot.from_file(Current.user, params[:file].read)
      if shot&.save
        render json: {id: shot.id}
      else
        render json: {error: "Could not save the provided file. #{shot.errors.full_messages.join(", ")}"}, status: :unprocessable_entity
      end
    end

    def destroy
      shot = Current.user.shots.find_by(id: params[:id])
      if shot
        shot.destroy!
        render json: {success: true}
      else
        render json: {error: "Shot not found"}, status: :not_found
      end
    end

    private

    def with_shot
      id = params[:id].presence || params[:shot_id]
      shot = Shot.find_by(id:)
      if shot
        yield(shot)
      else
        render json: {error: "Shot not found"}, status: :not_found
      end
    end
  end
end
