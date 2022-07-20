# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.fast_count
    ActiveRecord::Base.connection.execute("SELECT reltuples AS approximate FROM pg_class WHERE relname = '#{table_name}';").first["approximate"].to_i
  end
end
