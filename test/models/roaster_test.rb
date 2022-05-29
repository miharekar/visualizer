# frozen_string_literal: true

require "test_helper"

class RoasterTest < ActiveSupport::TestCase
  test "fixtures work" do
    assert_equal "Bani Beans", coffees(:hamasho).roaster.name
    assert_equal "The Barn", coffees(:bumba).roaster.name
    assert_equal "Bani Beans", coffee_bags(:one).coffee.roaster.name
    assert_equal "The Barn", coffee_bags(:two).coffee.roaster.name
  end
end
