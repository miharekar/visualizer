# frozen_string_literal: true

module Api
  class ShotsController < Api::BaseController
    def upload
      shot = Shot.from_file(current_user, file: params[:file], content: params[:content])
      if shot&.save
        render json: {id: shot.id}
      else
        head :unprocessable_entity
      end
    end
  end
end
