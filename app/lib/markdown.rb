module Markdown
  TAGS = Rails::Html::SafeListSanitizer.allowed_tags + %w[table thead tbody th tr td video]
  ATTRIBUTES = Rails::Html::SafeListSanitizer.allowed_attributes + %w[id style controls data-language value start]

  module_function

  def to_html(input)
    html = Kramdown::Document.new(input.to_s, input: "GFM").to_html
    html = sanitizer.sanitize(html, tags: TAGS, attributes: ATTRIBUTES)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("pre > code").each do |code|
      language = code["class"].to_s[/language-([a-zA-Z0-9_-]+)/, 1]
      code.parent["data-language"] = language if language
    end
    fragment.to_html
  end

  def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
