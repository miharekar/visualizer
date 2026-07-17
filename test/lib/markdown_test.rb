require "test_helper"

class MarkdownTest < ActiveSupport::TestCase
  test "converts GitHub Flavored Markdown to sanitized HTML" do
    html = Markdown.to_html("| Name | Value |\n| --- | --- |\n| Dose | 18g |\n\n<img src=\"x\" onerror=\"alert(1)\">")

    assert_includes html, "<table>"
    assert_includes html, "<td>18g</td>"
    assert_includes html, '<img src="x">'
    assert_not_includes html, "onerror"
  end

  test "marks fenced code language for Lexxy highlighting" do
    html = Markdown.to_html("```ruby\nputs :ok\n```")

    assert_includes html, '<pre data-language="ruby"'
  end
end
