module SanitizedRichText
  extend ActiveSupport::Concern

  included do
    before_validation :sanitize_rich_text
    before_save :sync_rich_text_plain_text
    validate :rich_text_cannot_include_media
  end

  def rich_text_html(attribute)
    public_send(attribute).body&.to_html.presence
  end

  def rich_text_plain_text(attribute)
    public_send(attribute).body&.to_plain_text.presence
  end

  private

  def sanitize_rich_text
    self.class::RICH_TEXT_ATTRIBUTES.each do |attribute|
      rich_text = loaded_rich_text(attribute)
      rich_text.body = RichTextSanitizer.sanitize(rich_text.body) if rich_text&.changed?
    end
  end

  def rich_text_cannot_include_media
    self.class::RICH_TEXT_ATTRIBUTES.each do |attribute|
      rich_text = loaded_rich_text(attribute)
      errors.add(attribute, "cannot include attachments or media") if rich_text && RichTextSanitizer.embedded_media?(rich_text.body)
    end
  end

  def sync_rich_text_plain_text
    self.class::RICH_TEXT_ATTRIBUTES.each do |attribute|
      rich_text = loaded_rich_text(attribute)
      self[attribute] = rich_text.body&.to_plain_text&.presence if rich_text&.changed?
    end
  end

  def loaded_rich_text(attribute)
    association_name = :"rich_text_#{attribute}"
    return unless association_cached?(association_name)

    association = association(association_name)
    association.target if association.loaded?
  end
end
