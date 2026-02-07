module Api
  class RoastersController < Api::BaseController
    before_action :verify_read_access, only: %i[index show]
    before_action :verify_write_access, only: %i[create update destroy]
    before_action :check_premium!, only: %i[create update destroy]
    before_action :load_roaster, only: %i[show update destroy]

    def index
      roasters = Current.user.roasters.order_by_name
      roasters, paging = paginate(roasters)
      render json: {data: roasters.map { {id: it.id, name: it.name} }, paging:}
    end

    def show
      render json: @roaster.to_api_json
    end

    def create
      roaster = Current.user.roasters.build(roaster_params)
      if roaster.save
        render json: roaster.to_api_json, status: :created
      else
        render json: {error: roaster.errors.full_messages.join(", ")}, status: :unprocessable_content
      end
    end

    def update
      if @roaster.update(roaster_params)
        render json: @roaster.to_api_json
      else
        render json: {error: @roaster.errors.full_messages.join(", ")}, status: :unprocessable_content
      end
    end

    def destroy
      @roaster.destroy!
      render json: {success: true}
    end

    private

    def load_roaster
      @roaster = Current.user.roasters.find_by(id: params[:id])
      render json: {error: "Roaster not found"}, status: :not_found unless @roaster
    end

    def roaster_params
      params.expect(roaster: %i[name website canonical_roaster_id])
    end
  end
end
