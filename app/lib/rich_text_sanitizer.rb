class RichTextSanitizer
  DISALLOWED_SELECTOR = "action-text-attachment, audio, embed, iframe, img, object, picture, script, source, style, video, figure[data-trix-attachment]"

  def self.sanitize(value)
    return if value.nil?

    source = value.respond_to?(:to_html) ? value.to_html : value.to_s
    fragment = Nokogiri::HTML5.fragment(source)
    fragment.css(DISALLOWED_SELECTOR).remove
    sanitizer = ActionText::ContentHelper.sanitizer
    tags = ActionText::ContentHelper.allowed_tags || sanitizer.class.allowed_tags + %w[figure figcaption]
    attributes = ActionText::ContentHelper.allowed_attributes || sanitizer.class.allowed_attributes
    sanitizer.sanitize(fragment.to_html, tags:, attributes: attributes + %w[data-language])
  end

  def self.from_plain_text(value)
    return if value.nil?

    paragraphs = ERB::Util.html_escape(value.to_s).split(/\n{2,}/).map do |paragraph|
      "<p>#{paragraph.gsub("\n", "<br>")}</p>"
    end
    sanitize(paragraphs.join)
  end

  def self.from_markdown(value)
    return if value.nil?

    fragment = Nokogiri::HTML5.fragment(Kramdown::Document.new(value.to_s, input: "GFM").to_html)
    fragment.css("pre > code").each do |code|
      language = code["class"].to_s[/language-([a-zA-Z0-9_-]+)/, 1]
      code.parent["data-language"] = language if language
    end
    sanitize(fragment.to_html)
  end
end
