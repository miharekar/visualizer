# frozen_string_literal: true

module Airtable
  class Table
    include Rails.application.routes.url_helpers

    API_URL = "https://api.airtable.com/v0"

    attr_reader :identity, :airtable_info

    def initialize(user, table_name, fields)
      @identity = user.identities.find_by(provider: "airtable")
      @table_name = table_name
      @fields = fields
      identity.ensure_valid_token!
      @airtable_info = identity.airtable_info || create_airtable_info
    end

    def update_record(record_id, fields)
      api_request("/#{airtable_info.base_id}/#{airtable_info.table_id}/#{record_id}", fields, method: :patch)
    end

    def update_records(records, merge_on: ["ID"])
      records.each_slice(10).map do |batch|
        data = {performUpsert: {fieldsToMergeOn: merge_on}, records: batch}
        response = api_request("/#{airtable_info.base_id}/#{airtable_info.table_id}", data, method: :patch)
        yield response if block_given?
      end
    end

    def get_records(minutes: 60)
      records = []
      query = {filterByFormula: "DATETIME_DIFF(NOW(), LAST_MODIFIED_TIME(), 'minutes') < #{minutes}"}
      loop do
        url = "/#{airtable_info.base_id}/#{airtable_info.table_id}?#{query.to_query}"
        data = api_request(url, method: :get)
        records += data["records"]
        query[:offset] = data["offset"]
        break if query[:offset].blank?
      end
      records
    end

    def webhook_payloads
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/payloads", method: :get)["payloads"]
    end

    def webhook_refresh
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/refresh", {})
    end

    def delete_record(record_id)
      api_request("/#{airtable_info.base_id}/#{airtable_info.table_id}/#{record_id}", method: :delete)
    end

    private

    def create_airtable_info
      base = set_base
      table = set_table(base)
      webhook = set_webhook(base, table)
      identity.create_airtable_info(base_id: base["id"], table_id: table["id"], table_fields: table["fields"].pluck("name"), webhook_id: webhook["id"])
    end

    def set_base
      bases = api_request("/meta/bases", method: :get)["bases"]
      if bases.any?
        @base = bases.find { |b| b["name"] == "Visualizer" } || bases.first
      else
        # TODO: Let user know we need access to a base
        identity.destroy
      end
    end

    def set_table(base)
      tables = api_request("/meta/bases/#{base["id"]}/tables", method: :get)["tables"]
      tables.find { |t| t["name"] == @table_name } || api_request("/meta/bases/#{base["id"]}/tables", {name: @table_name, fields: @fields, description: "Shots from Visualizer"})
    end

    def set_webhook(base, table)
      webhooks = api_request("/bases/#{base["id"]}/webhooks", method: :get)["webhooks"].select { |w| Time.zone.parse(w["expirationTime"]).future? }
      return webhooks.first if webhooks.any?

      data = {
        notificationUrl: airtable_url,
        specification: {options: {filters: {dataTypes: ["tableData"], changeTypes: ["update"], recordChangeScope: table["id"]}}}
      }
      api_request("/bases/#{base["id"]}/webhooks", data)
    end

    def create_missing_fields
      @fields.select { |f| airtable_info.table_fields.exclude?(f[:name]) }.each do |field|
        api_request("/meta/bases/#{airtable_info.base_id}/tables/#{airtable_info.table_id}/fields", field)
      end
      airtable_info.update(table_fields: @fields.pluck(:name))
    end

    def api_request(path, data = nil, method: :post)
      uri = URI.parse(API_URL + path)
      data = data.to_json unless data.nil?
      headers = {"Authorization" => "Bearer #{identity.token}", "Content-Type" => "application/json"}
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        attrs = [uri, data, headers].compact
        response = http.public_send(method, *attrs)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          raise DataError.new(response.body, data:, response:)
        end
      end
    end
  end
end
