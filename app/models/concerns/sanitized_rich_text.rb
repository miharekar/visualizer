module SanitizedRichText
  extend ActiveSupport::Concern

  class_methods do
    def has_sanitized_rich_text(name)
      has_rich_text(name)
      define_method(:"#{name}=") do |value|
        rich_text = public_send(name)
        rich_text.body = RichTextSanitizer.sanitize(value)
        self[name] = rich_text.body&.to_plain_text&.presence
      end
    end
  end

  def rich_text_html(attribute)
    RichTextSanitizer.sanitize(public_send(attribute).body).presence
  end

  def rich_text_plain_text(attribute)
    public_send(attribute).body&.to_plain_text.presence
  end
end
