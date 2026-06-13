module Api
  class CanonicalRoastersController < Api::BaseController
    def index
      roasters = CanonicalRoaster.search(params[:q].to_s).order(:name)
      roasters, paging = paginate(roasters)
      render json: {data: roasters.map { roaster_json(it) }, paging:}
    end

    private

    def roaster_json(roaster)
      roaster.attributes.slice("id", "name", "website", "country")
    end
  end
end
