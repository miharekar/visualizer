module RichTextShadow
  extend ActiveSupport::Concern

  class_methods do
    def has_shadowed_rich_text(*attributes)
      attributes.each do |attribute|
        has_rich_text attribute
        rich_text_reader = instance_method(attribute)

        define_method(attribute) do
          rich_text = rich_text_reader.bind_call(self)
          rich_text.body = Markdown.to_html(self[attribute]) if rich_text.body.blank? && self[attribute].present? && !rich_text.will_save_change_to_body?
          rich_text
        end
      end

      callback = -> { sync_rich_text_shadows(attributes) }
      before_save(callback)
    end
  end

  def rich_text_html(attribute)
    public_send(attribute).body&.to_html.to_s
  end

  private

  def sync_rich_text_shadows(attributes)
    attributes.each do |attribute|
      rich_text = public_send(attribute)
      self[attribute] = rich_text.body&.to_plain_text&.presence if rich_text.will_save_change_to_body?
    end
  end
end
