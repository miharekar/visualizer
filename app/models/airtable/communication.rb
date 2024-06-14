module Airtable
  module Communication
    API_URL = "https://api.airtable.com/v0"

    attr_reader :airtable_info

    def update_record(record_id, fields)
      api_request("/#{airtable_info.base_id}/#{airtable_info.tables[table_name]["id"]}/#{record_id}", fields, method: :patch)
    end

    def update_records(records, merge_on: ["ID"])
      records.each_slice(10).map do |batch|
        data = {performUpsert: {fieldsToMergeOn: merge_on}, records: batch}
        response = api_request("/#{airtable_info.base_id}/#{airtable_info.tables[table_name]["id"]}", data, method: :patch)
        yield response if block_given?
      end
    end

    def get_records(minutes: 60)
      records = []
      query = {filterByFormula: "DATETIME_DIFF(NOW(), LAST_MODIFIED_TIME(), 'minutes') < #{minutes}"}
      loop do
        url = "/#{airtable_info.base_id}/#{airtable_info.tables[table_name]["id"]}?#{query.to_query}"
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
      api_request("/#{airtable_info.base_id}/#{airtable_info.tables[table_name]["id"]}/#{record_id}", method: :delete)
    end

    private

    def api_request(path, data = nil, method: :post)
      uri = URI.parse(API_URL + path)
      data = data.to_json unless data.nil?
      headers = {"Authorization" => "Bearer #{identity.token}", "Content-Type" => "application/json"}
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        attrs = [uri, data, headers].compact
        response = http.public_send(method, *attrs)
        if response.is_a?(Net::HTTPSuccess)
          Oj.safe_load(response.body)
        else
          raise DataError.new(response.body, data:, response:)
        end
      end
    end
  end
end
