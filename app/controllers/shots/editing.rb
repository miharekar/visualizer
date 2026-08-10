module Shots
  module Editing
    private

    def update_shot_params
      allowed = [:profile_title, :barista, :bean_weight, :canonical_coffee_bag_id, *Parsers::Base::EXTRA_DATA_METHODS]
      allowed += [:image, :private_notes, *Shot::TASTING_ASSESSMENT_ATTRIBUTES, :tag_list, {tag_list: [], metadata: Current.user.shot_metadata_fields}] if Current.user.premium?
      allowed << :coffee_bag_id if Current.user.coffee_management_enabled?
      params.expect(shot: allowed)
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
