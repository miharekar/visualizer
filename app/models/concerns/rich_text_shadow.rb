module RichTextShadow
  extend ActiveSupport::Concern

  class_methods do
    def has_shadowed_rich_text(*attributes, enabled: nil)
      attributes.each do |attribute|
        has_rich_text attribute
        rich_text_reader = instance_method(attribute)

        define_method(attribute) do
          return self[attribute] unless enabled.nil? || instance_exec(&enabled)

          rich_text = rich_text_reader.bind_call(self)
          rich_text.body = Markdown.to_html(self[attribute]) if rich_text.body.blank? && self[attribute].present? && !rich_text.will_save_change_to_body?
          rich_text
        end
        define_method("#{attribute}=") do |value|
          if enabled.nil? || instance_exec(&enabled)
            rich_text_reader.bind_call(self).body = value
          else
            self[attribute] = value
          end
        end
      end

      callback = -> { sync_rich_text_shadows(attributes) }
      enabled ? before_save(callback, if: enabled) : before_save(callback)
    end
  end

  def rich_text_html(attribute)
    value = public_send(attribute)
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
