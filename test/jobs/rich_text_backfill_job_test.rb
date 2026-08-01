require "test_helper"

class RichTextBackfillJobTest < ActiveJob::TestCase
  test "backfills legacy markdown and is safe to rerun" do
    shot = create(:shot)
    coffee_bag = create(:coffee_bag)
    update = Update.create!(title: "Legacy", published_at: Time.current)
    write_legacy(shot, bean_notes: "- chocolate\n- floral", private_notes: "**Grind finer**")
    write_legacy(coffee_bag, notes: "*Sweet*")
    write_legacy(update, body: "# Heading")

    perform_enqueued_jobs { RichTextBackfillJob.perform_later }

    assert_equal %w[chocolate floral], Nokogiri::HTML5.fragment(shot.reload.rich_text_html(:bean_notes)).css("li").map(&:text)
    assert_equal "Grind finer", Nokogiri::HTML5.fragment(shot.rich_text_html(:private_notes)).at_css("strong").text
    assert_equal "Sweet", Nokogiri::HTML5.fragment(coffee_bag.reload.rich_text_html(:notes)).at_css("em").text
    assert_equal "Heading", Nokogiri::HTML5.fragment(update.reload.rich_text_html(:body)).at_css("h1").text
    assert_equal 4, ActionText::RichText.count

    perform_enqueued_jobs { RichTextBackfillJob.perform_later }

    assert_equal 4, ActionText::RichText.count
  end

  test "skips content removed by sanitization" do
    shot = create(:shot)
    write_legacy(shot, bean_notes: '<video src="https://example.com/shot.mp4"></video>')

    perform_enqueued_jobs { RichTextBackfillJob.perform_later }

    assert_equal 0, ActionText::RichText.where(record: shot).count
  end

  private

  def write_legacy(record, attributes)
    record.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
  end
end
