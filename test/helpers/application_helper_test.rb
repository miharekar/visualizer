require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders sanitized Markdown" do
    result = notes_text_from("**Bold**\n\n<img src=\"x\" onerror=\"alert(1)\">")

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
