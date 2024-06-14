module Airtable
  class Base
    include Rails.application.routes.url_helpers
    include Communication

    attr_reader :user, :identity, :table_name, :table_description, :airtable_info

    def initialize(user)
      @user = user
      @table_name = self.class.name.demodulize
      set_identity
      @airtable_info = identity.airtable_info || create_airtable_info
      set_table
    end

    private

    def set_identity
      @identity = user.identities.find_by(provider: "airtable")
      raise "Airtable identity not found for User##{user.id}" unless identity
      return if identity.valid_token?

      RefreshTokenJob.perform_later(identity)
      raise TokenError
    end

    def create_airtable_info
      base = set_base
      webhook = set_webhook(base)
      ActiveRecord::Base.transaction do
        AirtableInfo.where(identity:).destroy_all
        identity.create_airtable_info(base_id: base["id"], webhook_id: webhook["id"])
      end
    end

    def set_base
      bases = api_request("/meta/bases", method: :get)["bases"]
      if bases.any?
        bases.find { |b| b["name"] == "Visualizer" } || bases.first
      else
        identity.destroy
        raise BaseError
      end
    end

    def set_webhook(base)
      delete_existing_webhooks(base)
      data = {
        notificationUrl: Rails.application.routes.url_helpers.airtable_url,
        specification: {options: {filters: {dataTypes: ["tableData"], changeTypes: ["update"]}}}
      }
      api_request("/bases/#{base["id"]}/webhooks", data)
    end

    def delete_existing_webhooks(base)
      webhooks = api_request("/bases/#{base["id"]}/webhooks", method: :get)["webhooks"]
      webhooks.each do |webhook|
        api_request("/bases/#{base["id"]}/webhooks/#{webhook["id"]}", method: :delete)
      end
    end

    def set_table
      create_table unless airtable_info.tables&.key?(table_name)
      create_missing_fields
    end

    def create_table
      tables = api_request("/meta/bases/#{airtable_info.base_id}/tables", method: :get)["tables"]
      table = tables.find { |t| t["name"] == table_name } || api_request("/meta/bases/#{airtable_info.base_id}/tables", {name: table_name, fields: table_fields, description: self.class::TABLE_DESCRIPTION})
      airtable_info.update_tables(table_name, id: table["id"], fields: table["fields"])
    end

    def create_missing_fields(retrying: false)
      existing_fields = airtable_info.table_fields_for(table_name).keys
      table_fields.select { |f| existing_fields.exclude?(f["name"]) }.each do |field|
        api_request("/meta/bases/#{airtable_info.base_id}/tables/#{airtable_info.tables[table_name]["id"]}/fields", field)
      end
      airtable_info.update_tables(table_name, fields: table_fields)
    rescue Airtable::DataError => e
      raise if retrying || %w[DUPLICATE_OR_EMPTY_FIELD_NAME UNKNOWN_FIELD_NAME].exclude?(Oj.safe_load(e.message)["error"]["type"])

      reset_fields!
      retrying = true
      retry
    end

    def reset_fields!
      tables = api_request("/meta/bases/#{airtable_info.base_id}/tables", method: :get)
      fields = tables["tables"].find { |t| t["id"] == airtable_info.tables[table_name]["id"] }["fields"]
      airtable_info.update_tables(table_name, fields:)
    end
  end
end
