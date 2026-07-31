require "test_helper"

class RichTextSanitizerTest < ActiveSupport::TestCase
  test "preserves formatted text and removes scripts, attachments, and media" do
    html = <<~HTML
      <p style="background-image: url(https://example.com/tracker.png); color: red"><strong>Sweet</strong> shot<script>alert('no')</script></p>
      <img src="https://example.com/shot.jpg">
      <video src="https://example.com/shot.mp4"></video>
      <action-text-attachment sgid="signed-id"></action-text-attachment>
    HTML

    sanitized = RichTextSanitizer.sanitize(html)
    fragment = Nokogiri::HTML5.fragment(sanitized)

    assert_equal "Sweet shot", fragment.text.squish
    assert fragment.at_css("strong")
    assert_not fragment.at_css("script, img, video, action-text-attachment")
    assert_not_includes fragment.at_css("p").attributes, "style"
  end

  test "removes executable tags attributes and URL schemes" do
    html = <<~HTML
      <p onclick="alert('no')">Words</p>
      <a href="javascript:alert('no')" onmouseover="alert('no')">Link</a>
      <svg onload="alert('no')"><circle></circle></svg>
    HTML

    sanitized = RichTextSanitizer.sanitize(html)
    fragment = Nokogiri::HTML5.fragment(sanitized)

    assert_equal "Words\nLink", fragment.text.strip
    assert_not fragment.at_css("svg")
    assert_not_includes fragment.at_css("p").attributes, "onclick"
    assert_not_includes fragment.at_css("a").attributes, "href"
    assert_not_includes fragment.at_css("a").attributes, "onmouseover"
  end

  test "sanitizes stored rich text when serializing HTML" do
    shot = create(:shot, bean_notes: "<p>Safe</p>")
    shot.bean_notes.update_column(:body, '<p onclick="alert(1)">Unsafe</p>') # rubocop:disable Rails/SkipsModelValidations

    assert_equal "<p>Unsafe</p>", shot.reload.rich_text_html(:bean_notes)
  end

  test "converts plain text into paragraphs and line breaks" do
    html = RichTextSanitizer.from_plain_text("First <line>\nSecond line\n\nNext paragraph")

    assert_equal "<p>First &lt;line&gt;<br>Second line</p><p>Next paragraph</p>", html
  end

  test "converts Markdown and preserves code language" do
    html = RichTextSanitizer.from_markdown("- Chocolate\n- Floral\n\n```ruby\nputs :coffee\n```")
    fragment = Nokogiri::HTML5.fragment(html)

    assert_equal %w[Chocolate Floral], fragment.css("li").map(&:text)
    assert_equal "ruby", fragment.at_css("pre")["data-language"]
  end

  test "model sanitizes rich text before saving" do
    update = Update.create!(title: "Rich text", body: "<p>Words</p><img src=x>")

    assert_equal "<p>Words</p>", update.rich_text_html(:body)
    assert_equal "Words", update[:body]
    assert_empty update.body.embeds
  end
end
