module SanitizedRichText
  extend ActiveSupport::Concern

  class_methods do
    def has_sanitized_rich_text(name)
      has_rich_text(name)

      define_method(:"#{name}=") do |value|
        html = RichTextSanitizer.sanitize(value).presence
        plain_text = html && ActionText::Content.new(html).to_plain_text.presence
        association_name = :"rich_text_#{name}"

        if plain_text.nil?
          self[name] = nil
          public_send(association_name)&.mark_for_destruction
        else
          rich_text_association = association(association_name)
          rich_text_association.reset if rich_text_association.target&.marked_for_destruction?
          rich_text = public_send(name)
          rich_text.body = html
          self[name] = plain_text
        end
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
