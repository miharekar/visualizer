module RichTextShadow
  extend ActiveSupport::Concern

  class_methods do
    def has_shadowed_rich_text(*attributes, enabled: nil)
      attributes.each do |attribute|
        has_rich_text attribute
        rich_text_reader = instance_method(attribute)
        rich_text_writer = instance_method("#{attribute}=")

        define_method(attribute) do
          enabled.nil? || instance_exec(&enabled) ? rich_text_reader.bind_call(self) : self[attribute]
        end
        define_method("#{attribute}=") do |value|
          enabled.nil? || instance_exec(&enabled) ? rich_text_writer.bind_call(self, value) : self[attribute] = value
        end
      end

      callback = -> { sync_rich_text_shadows(attributes) }
      enabled ? before_save(callback, if: enabled) : before_save(callback)
    end
  end

  def shadowed_rich_text(attribute, enabled: true)
    return self[attribute] unless enabled

    rich_text = public_send(attribute)
    rich_text.body.present? || self[attribute].blank? ? rich_text : self[attribute]
  end

  def shadowed_rich_text_html(attribute, enabled: true)
    value = shadowed_rich_text(attribute, enabled:)
    value.respond_to?(:body) ? value.body&.to_html.to_s : Markdown.to_html(value)
  end

  private

  def sync_rich_text_shadows(attributes)
    attributes.each do |attribute|
      rich_text = public_send(attribute)
      if rich_text.will_save_change_to_body?
        self[attribute] = rich_text.body&.to_plain_text&.presence
      elsif rich_text.body.present?
        self[attribute] = rich_text.body.to_plain_text
      elsif self[attribute].present?
        public_send("#{attribute}=", Markdown.to_html(self[attribute]))
        self[attribute] = public_send(attribute).body.to_plain_text
      end
    end
  end
end
