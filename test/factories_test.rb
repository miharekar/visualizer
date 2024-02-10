# frozen_string_literal: true

require "test_helper"

class FactoriesTest < ActiveSupport::TestCase
  FactoryBot.factories.each do |factory|
    test "#{factory.name} is valid" do
      instance = build(factory.name)
      assert instance.valid?, "invalid factory: #{factory.name}, error messages: #{instance.errors.messages.inspect}"
    end

    factory.defined_traits.map(&:name).each do |trait|
      test "#{factory.name} with trait #{trait} is valid" do
        instance = build(factory.name, trait)
        assert instance.valid?, "invalid factory: #{factory.name} with trait: #{trait}, error messages: #{instance.errors.messages.inspect}"
      end
    end
  end
end
