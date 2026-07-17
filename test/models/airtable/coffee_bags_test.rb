require "test_helper"

module Airtable
  class CoffeeBagsTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, :with_airtable, :with_coffee_management)
      @roaster = create(:roaster, user: @user, airtable_id: "recRoaster")
      @coffee_bag = create(:coffee_bag, roaster: @roaster, airtable_id: "recBag")
    end

    test "uses HTML note field" do
      @coffee_bag.update!(notes: "<p><strong>Chocolate</strong></p>")

      fields = Airtable::CoffeeBags.new(@user).__send__(:prepare_record, @coffee_bag)[:fields]

      assert_includes fields["Notes HTML"], "<strong>Chocolate</strong>"
      assert_not_includes fields, "Notes"
    end
  end
end
