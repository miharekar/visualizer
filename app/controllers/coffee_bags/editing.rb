module CoffeeBags
  module Editing
    private

    def coffee_bag_params
      allowed = %i[name url canonical_coffee_bag_id roast_date frozen_date defrosted_date notes roaster_id image] + CoffeeBag::DISPLAY_ATTRIBUTES
      allowed << {metadata: Current.user.coffee_bag_metadata_fields}
      cb_params = params.expect(coffee_bag: allowed)
      cb_params[:roaster_id] = Current.user.roasters.find_by(id: params.dig(:coffee_bag, :roaster_id))&.id if params.dig(:coffee_bag, :roaster_id).present?
      cb_params[:legacy_notes] = cb_params.delete(:notes) if !Current.user.rich_text_enabled? && cb_params.key?(:notes)

      cb_params
    end
  end
end
