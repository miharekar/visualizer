# frozen_string_literal: true

require "test_helper"

class SluggableDummy
  def self.exists?(_)
    if @num_exists.positive?
      @num_exists -= 1
      return true
    end
    false
  end

  def self.before_validation(_)
  end

  def self.validates(*_args)
  end

  include Sluggable # rubocop:disable Layout/ClassStructure
  slug_from :title

  attr_reader :options

  def initialize(num_exists, **options)
    self.class.instance_variable_set(:@num_exists, num_exists)
    @options = options
  end

  def method_missing(method, *_args, **_options, &)
    return options[method] if respond_to_missing?(method)

    super
  end

  def respond_to_missing?(method)
    options.key?(method)
  end
end

class SluggableTest < ActiveSupport::TestCase
  test "it sets the slug" do
    dummy = SluggableDummy.new(0, title: "aa bb")
    assert_equal "aa-bb", dummy.__send__(:unique_slug)
  end

  test "sets the slug when there are already instances with that slug" do
    dummy = SluggableDummy.new(3, title: "aa bb")
    assert_equal "aa-bb-4", dummy.__send__(:unique_slug)
  end
end
