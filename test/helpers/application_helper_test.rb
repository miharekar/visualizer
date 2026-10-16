require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "web_link_to links http and https urls" do
    assert_dom_equal '<a class="x" href="https://example.com">https://example.com</a>', web_link_to("https://example.com", class: "x")
    assert_dom_equal '<a href="HTTP://example.com">HTTP://example.com</a>', web_link_to("HTTP://example.com")
  end

  test "web_link_to renders anything else as plain text" do
    ["javascript:alert(1)", " javascript:alert(1)", "JAVASCRIPT:alert(1)", "example.com", "data:text/html,x"].each do |url|
      assert_equal url, web_link_to(url, class: "x")
      assert_not_includes web_link_to(url).to_s, "<a"
    end
    assert_nil web_link_to(nil)
  end
end
