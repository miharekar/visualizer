require "test_helper"

class ShotTest < ActiveSupport::TestCase
  test "does not send shot uploaded email by default" do
    user = create(:user)

    assert_enqueued_jobs 0, only: ActionMailer::MailDeliveryJob do
      create(:shot, user:)
    end
  end

  test "sends shot uploaded email when user opted in" do
    user = create(:user, :premium, unsubscribed_from: [])

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      create(:shot, user:)
    end
  end

  test "does not send shot uploaded email when non-premium user opted in" do
    user = create(:user, unsubscribed_from: [])

    assert_enqueued_jobs 0, only: ActionMailer::MailDeliveryJob do
      create(:shot, user:)
    end
  end

  test "can have multiple tags" do
    user = create(:user)
    shot = create(:shot, user:)
    tag_1 = create(:tag, name: "Light roast", user:)
    tag_2 = create(:tag, name: "Ethiopia", user:)

    shot.tags << tag_1
    shot.tags << tag_2

    assert_equal 2, shot.tags.count
    assert_includes shot.tags, tag_1
    assert_includes shot.tags, tag_2
  end

  test "cannot have the same tag twice" do
    user = create(:user)
    shot = create(:shot, user:)
    tag = create(:tag, name: "Light roast", user:)

    shot.tags << tag
    assert_raises(ActiveRecord::RecordInvalid) do
      shot.tags << tag
    end

    assert_equal 1, shot.tags.count
  end

  test "can remove tags" do
    user = create(:user)
    shot = create(:shot, user:)
    tag = create(:tag, name: "Light roast", user:)

    shot.tags << tag
    assert_equal 1, shot.tags.count

    shot.tags.delete(tag)
    assert_equal 0, shot.tags.count
  end

  test "with_all_tag_slugs requires every tag" do
    user = create(:user)
    basket = create(:tag, name: "Basket", user:)
    high_speed = create(:tag, name: "High speed", user:)
    matching_shot = create(:shot, user:, tags: [basket, high_speed])
    create(:shot, user:, tags: [basket])

    assert_equal [matching_shot], Shot.with_all_tag_slugs("basket,high-speed").to_a
    assert_empty Shot.with_all_tag_slugs("basket,missing")
  end

  test "rich text notes sync to plain text columns" do
    user = create(:user)
    shot = create(:shot, user:, bean_notes: "<p><strong>Floral</strong> coffee</p>", espresso_notes: "<p>Chocolate</p>", private_notes: "<p>Grind finer</p>")

    assert_equal "Floral coffee", shot[:bean_notes]
    assert_equal "Chocolate", shot[:espresso_notes]
    assert_equal "Grind finer", shot[:private_notes]
    assert_equal [shot], Shot.where("bean_notes ILIKE ?", "%floral coffee%")

    shot.update!(bean_notes: "")

    assert_nil shot.reload[:bean_notes]
  end

  test "updating rich text notes touches shot" do
    shot = create(:shot)

    travel 1.minute do
      shot.update!(bean_notes: "<p>New notes</p>")
    end

    assert_operator shot.reload.updated_at, :>, shot.created_at
  end

  test "updating another field does not load rich text notes" do
    shot = create(:shot, bean_notes: "<p>Floral</p>")
    shot.reload
    queries = []
    callback = ->(*args) do
      payload = args.last
      queries << payload[:sql] if payload[:sql].include?("action_text_rich_texts")
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      shot.update!(profile_title: "Updated")
    end

    assert_empty queries
  end

  test "with notes preloads rich text embeds" do
    shot = create(:shot, bean_notes: "<p>Floral</p>", espresso_notes: "<p>Sweet</p>", private_notes: "<p>Grind finer</p>")
    shot = Shot.with_notes.find(shot.id)

    %i[bean_notes espresso_notes private_notes].each do |attribute|
      assert_predicate shot.public_send(attribute).association(:embeds_attachments), :loaded?
    end
  end

  test "does not store rich text for notes that were never set" do
    shot = create(:shot, bean_notes: nil, espresso_notes: nil, private_notes: nil)

    assert_equal 0, ActionText::RichText.where(record: shot).count
  end

  test "blanking a note removes its rich text row" do
    shot = create(:shot, bean_notes: "<p>Floral</p>")

    assert_equal 1, ActionText::RichText.where(record: shot).count

    shot.update!(bean_notes: "")

    assert_equal 0, ActionText::RichText.where(record: shot.reload).count
    assert_nil shot[:bean_notes]
  end

  test "setting a note after blanking it preserves the rich text row" do
    shot = create(:shot, bean_notes: "<p>Floral</p>")

    shot.bean_notes = ""
    shot.bean_notes = "<p>Sweet</p>"
    shot.save!

    assert_equal 1, ActionText::RichText.where(record: shot.reload).count
    assert_equal "<p>Sweet</p>", shot.rich_text_html(:bean_notes)
  end

  test "formatting only note edit still bumps updated_at" do
    shot = create(:shot, bean_notes: "<p>Floral</p>")
    original = shot.updated_at

    travel 1.minute do
      shot.update!(bean_notes: "<p><strong>Floral</strong></p>")
    end

    assert_operator shot.reload.updated_at, :>, original
  end

  test "tag list reuses existing tags" do
    user = create(:user, :premium)
    tags = %w[first second third].map { |name| create(:tag, name:, user:) }
    shot = create(:shot, user:)

    shot.update!(tag_list: "first,second,third")

    assert_equal tags, shot.tags.order(:name).to_a
    assert_equal 3, user.tags.count
  end

  test "tag list accepts an array" do
    user = create(:user, :premium)
    shot = create(:shot, user:)

    shot.update!(tag_list: ["First Tag", "second, third"])

    assert_equal ["first tag", "second", "third"], shot.tags.order(:name).pluck(:name)
  end

  test "days_frozen is nil without coffee bag" do
    shot = create(:shot)

    assert_nil shot.days_frozen
  end

  test "days_frozen uses coffee bag frozen window" do
    roaster = create(:roaster, user: create(:user, :with_coffee_management))
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: Date.new(2025, 1, 10), defrosted_date: nil)
    shot = create(:shot, user: roaster.user, coffee_bag:, start_time: Time.zone.parse("2025-01-15 12:00:00"))

    assert_equal 5, shot.days_frozen
  end
end
