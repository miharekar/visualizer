require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders sanitized rich text" do
    update = Update.new(body: "<strong>Bold</strong><img src=\"x\" onerror=\"alert(1)\">")
    result = notes_text_from(update.body)

    assert_includes result, "<strong>Bold</strong>"
    assert_not_includes result, "onerror"
    assert_includes result, 'data-controller="syntax-highlight"'
  end

  test "renders safe external FAQ links" do
    result = faq_markdown_text_from("[Docs](https://example.com)", link_class: "standard-link")

    assert_includes result, 'class="standard-link"'
    assert_includes result, 'target="_blank"'
    assert_includes result, 'rel="noopener noreferrer"'
  end
end
