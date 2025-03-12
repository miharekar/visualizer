class AirtableWebhookJob < AirtableJob
  class LastTransactionMismatchError < StandardError; end

  retry_on LastTransactionMismatchError, wait: :polynomially_longer

  attr_reader :airtable_info, :last_transaction, :webhook_payloads, :payloads, :record_timestamps, :relevant_tables, :relevant_timestamps

  def perform(airtable_info)
    @airtable_info = airtable_info
    @last_transaction = airtable_info.last_transaction.to_i

    get_payloads
    return update_last_cursor if payloads.empty?

    get_record_timestamps
    return update_last_cursor if record_timestamps.empty?

    get_relevant_timestamps
    download_updates
  end

  private

  def update_last_cursor
    airtable_info.update!(last_cursor: webhook_payloads["cursor"])
    self.class.perform_later(airtable_info) if webhook_payloads["mightHaveMore"]
  end

  def get_payloads
    @webhook_payloads = Airtable::Base.new(airtable_info.identity.user).webhook_payloads(cursor: airtable_info.last_cursor.to_i)
    @payloads = webhook_payloads["payloads"].reject do |p|
      p.dig("actionMetadata", "source") == "publicApi" || p["baseTransactionNumber"] <= last_transaction
    end
  end

  def get_record_timestamps
    @record_timestamps = {}
    @relevant_tables = airtable_info.tables.to_h { |k, t| [t["id"], "Airtable::#{k.delete(" ")}".constantize] }
    payloads.each do |payload|
      time = Time.iso8601(payload["timestamp"])
      payload["changedTablesById"].each do |table_id, table_payload|
        next unless relevant_tables.key?(table_id)

        @record_timestamps[table_id] ||= {}
        table_payload["changedRecordsById"].each_key do |record_id|
          @record_timestamps[table_id][record_id] ||= []
          @record_timestamps[table_id][record_id] << time
        end
      end
    end
  end

  def get_relevant_timestamps
    @relevant_timestamps = {}
    record_timestamps.each do |table_id, timestamps|
      @relevant_timestamps[table_id] ||= []
      table_name = relevant_tables[table_id]::DB_TABLE_NAME
      airtable_info.identity.user.public_send(table_name).where(airtable_id: timestamps.keys).find_each do |record|
        @relevant_timestamps[table_id] += timestamps[record.airtable_id].select { |t| t > record.updated_at }
      end
    end
  end

  def download_updates
    ActiveRecord::Base.transaction do
      relevant_timestamps.each do |table_id, relevant|
        next if relevant.empty?

        minutes = ((Time.current - relevant.min) / 60).ceil
        timestamps = record_timestamps[table_id].transform_values(&:max)
        relevant_tables[table_id].new(airtable_info.identity.user).download(minutes:, timestamps:)
      end

      raise LastTransactionMismatchError if airtable_info.reload.last_transaction.to_i != last_transaction

      airtable_info.update!(
        last_transaction: payloads.pluck("baseTransactionNumber").max,
        last_cursor: webhook_payloads["cursor"]
      )
    end
  end
end
