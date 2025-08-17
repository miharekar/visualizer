module Api
  class ShotsController < Api::BaseController
    attr_reader :file_content

    before_action :verify_upload_access, only: %i[upload]
    before_action :verify_write_access, only: %i[destroy]
    before_action :extract_file_content, only: %i[upload]

    def index
      shots = Current.user.present? ? Current.user.shots : Shot.visible
      shots = shots.non_premium unless Current.user&.premium?
      shots = params[:sort] == "updated_at" ? shots.order(updated_at: :desc) : shots.by_start_time
      shots = shots.select(:id, :start_time, :user_id, :updated_at)
      shots, paging = paginate(shots)
      data = shots.map { {clock: it.start_time.to_i, id: it.id, updated_at: it.updated_at.to_i} }
      render json: {data:, paging:}
    rescue ActiveRecord::ActiveRecordError => e
      Appsignal.report_error(e)
      render json: {error: "Could not paginate"}, status: :unprocessable_content
    end

    def show
      with_shot do |shot|
        render json: shot.to_api_json(format: params[:format], include_information: !params[:essentials].presence)
      end
    end
    alias_method :download, :show

    def profile
      with_shot do |shot|
        if shot.information&.gaggiuino?
          send_data shot.information&.profile_fields, filename: "#{shot.profile_title} from Visualizer.json", type: "application/json", disposition: "attachment"
        elsif shot.information&.gaggimate?
          render json: shot.information&.profile_fields, filename: "#{shot.profile_title} from Visualizer.json", type: "application/json", disposition: "attachment"
        elsif params[:format] == "csv"
          send_data shot.information&.csv_profile, filename: "#{shot.profile_title} from Visualizer.csv", type: "text/csv", disposition: "attachment"
        elsif params[:format] == "json" && shot.information&.json_profile_fields.present?
          render json: shot.information&.json_profile
        elsif shot.information&.tcl_profile_fields.present?
          send_data shot.information.tcl_profile, filename: "#{shot.profile_title} from Visualizer.tcl", type: "application/x-tcl", disposition: "attachment"
        else
          render json: {error: "Shot does not have a profile"}, status: :unprocessable_content
        end
      end
    end

    def shared
      shared = SharedShot.find_by(code: params[:code].to_s.upcase)
      if shared
        render json: shared.shot.to_api_json(format: params[:format], include_information: params[:with_data].presence)
      elsif Current.user.present?
        distinct_shots = Current.user.shared_shots.distinct.pluck(:shot_id)
        render json: Shot.where(id: distinct_shots).map { |s| s.to_api_json(format: params[:format], include_information: params[:with_data].presence) }
      else
        render json: {error: "Shared shot not found"}, status: :not_found
      end
    end

    def upload
      shot = Shot.from_file(Current.user, file_content)
      if shot&.save
        render json: {id: shot.id}
      else
        render json: {error: "Could not save the provided file. #{shot.errors.full_messages.join(", ")}"}, status: :unprocessable_content
      end
    end

    def destroy
      shot = Current.user.shots.find_by(id: params[:id])
      authorize shot
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

    def extract_file_content
      @file_content = case request.content_type
      when /multipart\/form-data/
        params[:file]&.read
      when /application\/json/
        request.raw_post
      end
      return if file_content.present?

      render json: {error: "No shot file provided. Provide a file parameter with a multipart/form-data request or a JSON body with a valid JSON object."}, status: :unprocessable_content
    end
  end
end
