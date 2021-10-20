# frozen_string_literal: true

require "test_helper"

class ShareableProfileTest < ActiveSupport::TestCase
  test "creates a code when saving" do
    sp = ShareableProfile.new(shot: shots(:one))
    assert_nil sp.code
    sp.save!
    assert_not_nil sp.code
    assert_equal 4, sp.code.length
  end

  test "it does not change the code" do
    sp = ShareableProfile.new(shot: shots(:one), code: "ASDF")
    sp.save!
    code = sp.code
    assert_equal code, sp.code
    sp.save!
    assert_equal code, sp.code
  end

  test "it does not overwrite the code" do
    sp = ShareableProfile.new(shot: shots(:one), code: "ASDF")
    sp.save!
    assert_equal "ASDF", sp.code
  end

  test "it creates new unique code if current one exists" do
    ShareableProfile.create!(shot: shots(:one), code: "ASDF")
    sp = ShareableProfile.new(shot: shots(:one), code: "ASDF")
    sp.save!
    assert_not_equal "ASDF", sp.code
  end
end
