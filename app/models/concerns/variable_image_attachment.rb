module VariableImageAttachment
  extend ActiveSupport::Concern

  class_methods do
    def validates_variable_image(name)
      validate if: -> { attachment_changes.key?(name.to_s) } do
        attachment = public_send(name)
        errors.add(name, "must be a supported image") if attachment.attached? && !attachment.variable?
      end
    end
  end
end
