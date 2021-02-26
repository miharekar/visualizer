# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :slug_source

    def slug_from(column)
      @slug_source = column
    end
  end

  included do
    before_save :set_slug
  end

  private

  def set_slug
    return if slug_source.blank? || slug.present?

    self.slug = unique_slug
  end

  def slug_source
    public_send(self.class.slug_source)
  end

  def unique_slug
    slug = slug_source.to_s.parameterize
    return slug unless slug_taken?(slug)

    (2..).each do |i|
      new_slug = "#{slug}-#{i}"
      break new_slug unless slug_taken?(new_slug)
    end
  end

  def slug_taken?(slug)
    self.class.exists?(slug: slug)
  end
end
