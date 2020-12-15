# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    def upload
      file_content = ""

      if params[:file].present?
        file_content = File.read(params[:file])
      elsif params[:content].present?
        file_content = params[:content]
      end

      shot = Shot.from_file_content(current_user, file_content)
      if shot&.save
        render json: {id: shot.id}
      else
        head :unprocessable_entity
      end
    end
  end
end
