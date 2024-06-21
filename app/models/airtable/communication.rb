module Airtable
  module Communication
    API_URL = "https://api.airtable.com/v0"

    attr_reader :airtable_info

    def upload(record)
      if record.airtable_id
        update_record(record.airtable_id, prepare_record(record))
      else
        upload_multiple(record.class.where(id: record.id))
      end
    end

    def upload_multiple(records)
      return unless records.exists?

      prepared_records = records.with_attached_image.map { |record| prepare_record(record) }
      update_records(prepared_records) do |response|
        response["records"].each do |record_data|
          record = records.find_by(id: record_data["fields"]["ID"])
          next unless record

          record.update_columns(airtable_id: record_data["id"])
        end
      end
    end

    def download(minutes: 60, timestamps: {})
      request_time = Time.current
      records = get_records(minutes:)
      local_records = user.public_send(self.class::DB_TABLE_NAME).where(airtable_id: records.pluck("id")).index_by(&:airtable_id)
      records.each do |record|
        local_record = local_records[record["id"]]
        next unless local_record

        updated_at = timestamps[record["id"]].presence || request_time
        attributes = local_record_attributes(local_record, record)
        local_record.update!(attributes.merge(skip_airtable_sync: true, updated_at:))
      end
    end

    def delete(airtable_id)
      delete_record(airtable_id)
    end

    def webhook_payloads(cursor: nil)
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/payloads?cursor=#{cursor.to_i}", method: :get)
    end

    def webhook_refresh
      api_request("/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/refresh", {})
    end

    private

    def update_record(record_id, fields)
      api_request("/#{airtable_info.base_id}/#{airtable_info.tables[self.class::TABLE_NAME]["id"]}/#{record_id}", fields, method: :patch)
    end

    def update_records(records, merge_on: ["ID"])
      records.each_slice(10).map do |batch|
        data = {performUpsert: {fieldsToMergeOn: merge_on}, records: batch}
        response = api_request("/#{airtable_info.base_id}/#{airtable_info.tables[self.class::TABLE_NAME]["id"]}", data, method: :patch)
        yield response if block_given?
      end
    end

    def get_records(minutes: 60)
      records = []
      query = {filterByFormula: "DATETIME_DIFF(NOW(), LAST_MODIFIED_TIME(), 'minutes') < #{minutes}"}
      loop do
        url = "/#{airtable_info.base_id}/#{airtable_info.tables[self.class::TABLE_NAME]["id"]}?#{query.to_query}"
        data = api_request(url, method: :get)
        records += data["records"]
        query[:offset] = data["offset"]
        break if query[:offset].blank?
      end
      records
    end

    def delete_record(record_id)
      api_request("/#{airtable_info.base_id}/#{airtable_info.tables[self.class::TABLE_NAME]["id"]}/#{record_id}", method: :delete)
    end

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
