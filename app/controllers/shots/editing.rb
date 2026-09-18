module Shots
  module Editing
    private

    def update_shot_params
      params.expect(shot: Shot.editable_attributes(Current.user))
    end

    def apply_brewdata_updates
      return if @shot.information.blank?
      return if params[:shot][:brewdata].blank?

      params[:shot][:brewdata].each do |path, value|
        group, key = path.to_s.split("/", 2)
        next if group.blank? || key.blank?

        @shot.information.brewdata[group][key] = value
      end

      @shot.information.save
    end
  end
end
