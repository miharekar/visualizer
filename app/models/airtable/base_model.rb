# frozen_string_literal: true

module Airtable
  class BaseModel
    attr_reader :user, :table_name, :table_fields

    def initialize(user)
      @user = user
      @table_name = self.class.name.demodulize.pluralize
      @table_fields = prepare_table_fields
    end

    def table
      @table ||= Table.new(self)
    end

    private

    def prepare_table_fields
      raise NotImplementedError
    end
  end
end
