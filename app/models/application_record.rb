class ApplicationRecord < ActiveRecord::Base
  UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i

  primary_abstract_class
  self.implicit_order_column = :created_at
end
