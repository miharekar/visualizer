module Api
  class RoastersController < Api::BaseController
    before_action :verify_read_access

    def index
      roasters = Current.user.roasters.order_by_name
      roasters, paging = paginate(roasters)
      render json: {data: roasters.map { {id: it.id, name: it.name} }, paging:}
    end

    def show
      roaster = Current.user.roasters.find(params[:id])
      render json: roaster.to_api_json
    end
  end
end
