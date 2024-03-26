require "test_helper"

class LockableTest < ActiveSupport::TestCase
  class LockableDummy
    include Lockable
  end

  test "raises ArgumentError if no block is given" do
    assert_raises(ArgumentError, "Block required") do
      LockableDummy.new.with_lock!("test_lock")
    end
  end
end
