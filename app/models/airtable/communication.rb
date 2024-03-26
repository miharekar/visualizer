module Airtable
  module Communication
    API_URL = "https://api.airtable.com/v0"

    attr_reader :airtable_info

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

    def webhook_payloads(cursor: nil)
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/payloads?cursor=#{cursor.to_i}", method: :get)
    end

    def webhook_refresh
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/refresh", {})
    end

    def delete_record(record_id)
      api_request("/#{airtable_info.base_id}/#{airtable_info.table_id}/#{record_id}", method: :delete)
    end

    private

    def prepare_table
      @airtable_info = identity.airtable_info || create_airtable_info
      create_missing_fields
    end

    def create_airtable_info
      base = set_base
      table = set_table(base)
      webhook = set_webhook(base, table)
      ActiveRecord::Base.transaction do
        AirtableInfo.where(identity:).destroy_all
        identity.create_airtable_info(base_id: base["id"], table_id: table["id"], table_fields: table["fields"].pluck("name"), webhook_id: webhook["id"])
      end
    end

    def set_base
      bases = api_request("/meta/bases", method: :get)["bases"]
      if bases.any?
        @base = bases.find { |b| b["name"] == "Visualizer" } || bases.first
      else
        identity.destroy
      end
    end

    def set_table(base)
      tables = api_request("/meta/bases/#{base["id"]}/tables", method: :get)["tables"]
      tables.find { |t| t["name"] == table_name } || api_request("/meta/bases/#{base["id"]}/tables", {name: table_name, fields: table_fields, description: "Shots from Visualizer"})
    end

    def set_webhook(base, table)
      delete_existing_webhooks(base)
      data = {
        notificationUrl: Rails.application.routes.url_helpers.airtable_url,
        specification: {options: {filters: {dataTypes: ["tableData"], changeTypes: ["update"], recordChangeScope: table["id"]}}}
      }
      api_request("/bases/#{base["id"]}/webhooks", data)
    end

    def delete_existing_webhooks(base)
      webhooks = api_request("/bases/#{base["id"]}/webhooks", method: :get)["webhooks"]
      webhooks.each do |webhook|
        api_request("/bases/#{base["id"]}/webhooks/#{webhook["id"]}", method: :delete)
      end
    end

    def create_missing_fields(retrying: false)
      table_fields.select { |f| airtable_info.table_fields.exclude?(f[:name]) }.each do |field|
        api_request("/meta/bases/#{airtable_info.base_id}/tables/#{airtable_info.table_id}/fields", field)
      end
      airtable_info.update(table_fields: table_fields.pluck(:name))
    rescue Airtable::DataError => e
      raise if retrying || %w[DUPLICATE_OR_EMPTY_FIELD_NAME UNKNOWN_FIELD_NAME].exclude?(Oj.load(e.message)["error"]["type"])

      reset_fields!
      retrying = true
      retry
    end

    def reset_fields!
      tables = api_request("/meta/bases/#{airtable_info.base_id}/tables", method: :get)
      airtable_fields = tables["tables"].find { |t| t["id"] == airtable_info.table_id }["fields"].pluck("name")
      actual_fields = airtable_fields & table_fields.pluck(:name)
      airtable_info.update(table_fields: actual_fields)
    end

    def api_request(path, data = nil, method: :post)
      uri = URI.parse(API_URL + path)
      data = data.to_json unless data.nil?
      headers = {"Authorization" => "Bearer #{identity.token}", "Content-Type" => "application/json"}
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        attrs = [uri, data, headers].compact
        response = http.public_send(method, *attrs)
        if response.is_a?(Net::HTTPSuccess)
          Oj.load(response.body)
        else
          raise DataError.new(response.body, data:, response:)
        end
      end
    end
  end
end
