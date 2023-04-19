# frozen_string_literal: true

class AirtableWebhookJob < ApplicationJob
  queue_as :default

  def perform(airtable_info)
    user = airtable_info.identity.user
    table = Airtable::Table.new(user, Airtable::ShotSync::TABLE_NAME, airtable_info.table_fields)
    payloads = table.webhook_payloads.reject { |p| p.dig("actionMetadata", "source") == "publicApi" }

    record_timestamps = {}
    payloads.each do |payload|
      time = Time.iso8601(payload["timestamp"])
      payload.dig("changedTablesById", airtable_info.table_id, "changedRecordsById").keys.each do |record_id|
        record_timestamps[record_id] ||= []
        record_timestamps[record_id] << time
      end
    end

    relevant_timestamps = []
    user.shots.where(airtable_id: record_timestamps.keys).find_each do |shot|
      relevant_timestamps += record_timestamps[shot.airtable_id].select { |t| t > shot.updated_at }
    end
    return if relevant_timestamps.empty?

    minutes = ((Time.zone.now - relevant_timestamps.min) / 60).ceil
    timestamps = record_timestamps.transform_values { |v| v.max }
    Airtable::ShotSync.new(user).download(minutes:, timestamps:)
  end
end
