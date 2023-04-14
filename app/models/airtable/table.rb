# frozen_string_literal: true

module Airtable
  class Table
    API_URL = "https://api.airtable.com/v0"
    BASE_NAME = "Visualizer"

    attr_reader :identity

    def initialize(user, table_name, fields)
      @identity = user.identities.find_by(provider: "airtable")
      identity.ensure_valid_token!
      set_base
      set_table(table_name, fields)
      set_fields(fields)
    end

    def update_record(record_id, fields)
      data_request("/#{@base["id"]}/#{@table["id"]}/#{record_id}", fields, method: :patch)
    end

    def update_records(records, merge_on: ["ID"])
      returned_records = []
      records.each_slice(10).map do |batch|
        data = {performUpsert: {fieldsToMergeOn: merge_on}, records: batch}
        response = data_request("/#{@base["id"]}/#{@table["id"]}", data, method: :patch)
        returned_records += response["records"]
      end
      returned_records
    end

    def get_records(minutes: 60)
      records = []
      query = {filterByFormula: "DATETIME_DIFF(NOW(), LAST_MODIFIED_TIME(), 'minutes') < #{minutes}"}
      loop do
        url = "/#{@base["id"]}/#{@table["id"]}?#{query.to_query}"
        data = get_request(url)
        records += data["records"]
        query[:offset] = data["offset"]
        break if query[:offset].blank?
      end
      records
    end

    def delete_record(record_id)
      data_request("/#{@base["id"]}/#{@table["id"]}/#{record_id}", nil, method: :delete)
    end

    private

    def set_base
      bases = get_request("/meta/bases")["bases"]
      if bases.any?
        @base = bases.find { |b| b["name"] == BASE_NAME } || bases.first
      else
        # TODO: Let user know we need access to a base
        identity.destroy
      end
    end

    def set_table(name, fields)
      tables = get_request("/meta/bases/#{@base["id"]}/tables")["tables"]
      @table = tables.find { |t| t["name"] == name }
      return if @table

      @table = data_request("/meta/bases/#{@base["id"]}/tables", {name:, fields:, description: "Shots from Visualizer"})
    end

    def set_fields(fields)
      existing = @table["fields"].pluck("name")
      fields.select { |f| existing.exclude?(f[:name]) }.each do |field|
        data_request("/meta/bases/#{@base["id"]}/tables/#{@table["id"]}/fields", field)
      end
    end

    def get_request(path)
      Rails.logger.debug { "Sending GET request to #{path}" }
      uri = URI.parse(API_URL + path)
      headers = {"Authorization" => "Bearer #{identity.token}"}
      response = Net::HTTP.get(uri, headers)
      JSON.parse(response)
    end

    def data_request(path, data, method: :post)
      Rails.logger.debug { "Sending #{method} request to #{path} with data #{data}" }
      uri = URI.parse(API_URL + path)
      data = data.to_json if data.present?
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
