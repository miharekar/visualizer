# frozen_string_literal: true

module Airtable
  class Base
    include Communication

    attr_reader :user

    def initialize(user)
      @user = user
      @table_name = self.class.name.demodulize
      @table_fields = prepare_table_fields
      prepare_table
    end

    private

    def prepare_table_fields
      raise NotImplementedError
    end
  end
end
