module Shots
  module Editing
    class InvalidImageError < StandardError; end

    private

    def update_shot_params
      allowed = [:image, :profile_title, :barista, :bean_weight, :private_notes, :canonical_coffee_bag_id, *Parsers::Base::EXTRA_DATA_METHODS]
      allowed << [:tag_list, {metadata: Current.user.metadata_fields}] if Current.user.premium?
      allowed << :coffee_bag_id if Current.user.coffee_management_enabled?
      params.expect(shot: allowed)
    end

    def attach_image(field)
      return if field.blank?
      raise InvalidImageError, "Image must be a valid image file." unless ActiveStorage.variable_content_types.include?(field.content_type)

      @shot.image.attach(field)
    end
  end
end
