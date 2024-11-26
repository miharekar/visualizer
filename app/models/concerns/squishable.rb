module Squishable
  extend ActiveSupport::Concern

  included do
    before_validation :squish_attributes
  end

  class_methods do
    attr_reader :squishable_attributes

    def squishes(*attributes)
      @squishable_attributes = attributes
    end
  end

  private

  def squish_attributes
    self.class.squishable_attributes.each do |attr|
      self[attr] = self[attr].to_s.squish if self[attr].respond_to?(:squish)
    end
  end
end
