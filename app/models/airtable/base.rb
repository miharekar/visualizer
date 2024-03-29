module Airtable
  class Base
    include Communication

    attr_reader :user, :identity, :table_name

    def initialize(user)
      @user = user
      @table_name = self.class.name.demodulize
      set_identity
      prepare_table
    end

    private

    def set_identity
      @identity = user.identities.find_by(provider: "airtable")
      raise "Airtable identity not found for User##{user.id}" unless identity
      return if identity.valid_token?

      RefreshTokenJob.perform_later(identity)
      raise TokenError
    end

    def table_fields
      raise NotImplementedError
    end
  end
end
