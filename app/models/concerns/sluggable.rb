module Sluggable
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :slug_source, :slug_scope

    def find_by_slug_or_id(slug_or_id)
      find_by(slug: slug_or_id) || find_by(id: slug_or_id)
    end

    def find_by_slug_or_id!(slug_or_id)
      find_by(slug: slug_or_id) || find(slug_or_id)
    end

    def slug_from(column)
      @slug_source = column
    end

    def slug_scope_to(scope)
      @slug_scope = scope
    end
  end

  included do
    before_validation :generate_slug
  end

  private

  def generate_slug
    return if slug.present?

    self.slug = unique_slug
  end

  def unique_slug
    base_slug = public_send(self.class.slug_source).to_s.parameterize
    return base_slug unless slug_exists?(base_slug)

    (2..).each do |i|
      new_slug = "#{base_slug}-#{i}"
      break new_slug unless slug_exists?(new_slug)
    end
  end

  def slug_exists?(test_slug)
    scope = self.class
    if self.class.slug_scope
      scope_value = public_send(self.class.slug_scope)
      scope = scope.where(self.class.slug_scope => scope_value)
    end
    scope.exists?(slug: test_slug)
  end
end
