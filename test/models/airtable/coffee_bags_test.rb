require "test_helper"

module Airtable
  class CoffeeBagsTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, :with_airtable, :with_coffee_management)
      @roaster = create(:roaster, user: @user, airtable_id: "recRoaster")
      @coffee_bag = create(:coffee_bag, roaster: @roaster, airtable_id: "recBag")
    end

    test "uses HTML note field for rich text users" do
      @coffee_bag.update!(notes: "<p><strong>Chocolate</strong></p>")

      fields = Airtable::CoffeeBags.new(@user).__send__(:prepare_record, @coffee_bag)[:fields]

      assert_includes fields["Notes HTML"], "<strong>Chocolate</strong>"
      assert_not_includes fields, "Notes"
    end

    test "uses existing rich text field for opted-out users" do
      @user.update_columns(rich_text_enabled: false) # rubocop:disable Rails/SkipsModelValidations
      @coffee_bag.update_columns(notes: "**Chocolate**") # rubocop:disable Rails/SkipsModelValidations

      fields = Airtable::CoffeeBags.new(@user).__send__(:prepare_record, @coffee_bag)[:fields]

      assert_equal "**Chocolate**", fields["Notes"]
      assert_not_includes fields, "Notes HTML"
    end
  end
end
