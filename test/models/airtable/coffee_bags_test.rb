require "test_helper"

module Airtable
  class CoffeeBagsTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, :with_airtable, :with_coffee_management)
      @roaster = create(:roaster, user: @user, airtable_id: "recRoaster")
      @coffee_bag = create(:coffee_bag, roaster: @roaster, notes: "<p><strong>Sweet</strong><br>Floral</p>")
      clear_enqueued_jobs
    end

    test "it uploads notes as plain text" do
      fields = Airtable::CoffeeBags.new(@user).__send__(:prepare_record, @coffee_bag)[:fields]

      assert_equal "Sweet\nFloral", fields["Notes"]
    end

    test "it does not download notes from airtable" do
      record = {"fields" => {"Name" => @coffee_bag.name, "Notes" => "Remote notes", "Roaster" => [@roaster.airtable_id]}}

      Airtable::CoffeeBags.new(@user).__send__(:update_local_record, @coffee_bag, record, Time.current)

      assert_equal "Sweet\nFloral", @coffee_bag.reload.notes.to_plain_text
    end
  end
end
