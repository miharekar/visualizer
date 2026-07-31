class RichTextSanitizer
  DISALLOWED_SELECTOR = "action-text-attachment, audio, embed, iframe, img, object, picture, script, source, style, video, figure[data-trix-attachment]"

  def self.sanitize(value)
    return if value.nil?

    source = value.respond_to?(:to_html) ? value.to_html : value.to_s
    fragment = clean_fragment(source)
    fragment = clean_fragment(ActionText::Content.new(fragment.to_html).to_html)
    fragment.to_html
  end

  def self.clean_fragment(html)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css(DISALLOWED_SELECTOR).remove
    fragment.css(".lexxy-content").each { it.replace(it.children) }
    fragment.css("[style]").each { it.remove_attribute("style") if it["style"].match?(/url\s*\(/i) }
    fragment
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
    add_code_languages(fragment)
    sanitize(fragment.to_html)
  end

  def self.add_code_languages(fragment)
    fragment.css("pre > code").each do |code|
      language = code["class"].to_s[/language-([a-zA-Z0-9_-]+)/, 1]
      code.parent["data-language"] = language if language
    end
  end

  def self.embedded_media?(value)
    Nokogiri::HTML5.fragment(value.to_s).at_css(DISALLOWED_SELECTOR).present?
  end
end
