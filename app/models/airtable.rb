# frozen_string_literal: true

class Airtable
  API_URL = "https://api.airtable.com/v0"
  BASE_NAME = "Visualizer"
  TABLE_NAME = "Shots"

  attr_reader :user, :identity

  def initialize(user)
    @user = user
    @identity = user.identities.find_by(provider: "airtable")
    identity.ensure_valid_token!
    set_base
    set_table
  end

  def sync(limit = 10)
    shot_data = user.shots.order(created_at: :desc).limit(limit).map { |shot| shot.for_airtable }
    shot_data.each_slice(10).map do |batch|
      data = {performUpsert: {fieldsToMergeOn: ["ID"]}, records: batch}
      data_request("/#{@base["id"]}/#{@table["id"]}", data, method: :patch)
    end
  end

  private

  def set_base
    bases = get_request("/meta/bases")["bases"]
    if bases.any?
      @base = bases.find { |b| b["name"] == BASE_NAME } || bases.first
    else
      # TODO: Let user know we need access to a base
      @identity.destroy
    end
  end

  def set_table
    tables = get_request("/meta/bases/#{@base["id"]}/tables")["tables"]
    @table = tables.find { |t| t["name"] == TABLE_NAME }
    return if @table

    @table = data_request("/meta/bases/#{@base["id"]}/tables", {name: TABLE_NAME, description: "Shots from Visualizer", fields: Shot.airtable_fields})
  end

  def get_request(path)
    uri = URI.parse(API_URL + path)
    headers = {"Authorization" => "Bearer #{identity.token}"}
    response = Net::HTTP.get(uri, headers)
    JSON.parse(response)
  end

  def data_request(path, data, method: :post)
    uri = URI.parse(API_URL + path)
    headers = {"Authorization" => "Bearer #{identity.token}", "Content-Type" => "application/json"}
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      response = http.public_send(method, uri, data.to_json, headers)
      JSON.parse(response.body)
    end
  end
end
