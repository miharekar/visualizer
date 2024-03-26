class AirtableWebhookJob < AirtableJob
  class LastTransactionMismatchError < StandardError; end

  retry_on LastTransactionMismatchError, wait: :polynomially_longer

  def perform(airtable_info)
    @airtable_info = airtable_info
    @user = @airtable_info.identity.user
    @shots = Airtable::Shots.new(@user)
    @last_transaction = @airtable_info.last_transaction.to_i
    @last_cursor = @airtable_info.last_cursor.to_i

    get_payloads
    return if @payloads.empty?

    get_record_timestamps
    return if @record_timestamps.empty?

    get_relevant_timestamps
    return if @relevant_timestamps.empty?

    download_shot_updates
  end

  private

  def get_payloads
    @webhook_payloads = @shots.webhook_payloads(cursor: @last_cursor)
    @payloads = @webhook_payloads["payloads"].reject do |p|
      p.dig("actionMetadata", "source") == "publicApi" || p["baseTransactionNumber"] <= @last_transaction
    end
  end

  def get_record_timestamps
    @record_timestamps = {}
    @payloads.each do |payload|
      time = Time.iso8601(payload["timestamp"])
      changed_records = payload.dig("changedTablesById", @airtable_info.table_id, "changedRecordsById")
      next if changed_records.blank?

      changed_records.keys.each do |record_id|
        @record_timestamps[record_id] ||= []
        @record_timestamps[record_id] << time
      end
    end
    @record_timestamps
  end

  def get_relevant_timestamps
    @relevant_timestamps = []
    @user.shots.where(airtable_id: @record_timestamps.keys).find_each do |shot|
      @relevant_timestamps += @record_timestamps[shot.airtable_id].select { |t| t > shot.updated_at }
    end
    @relevant_timestamps
  end

  def download_shot_updates
    ActiveRecord::Base.transaction do
      minutes = ((Time.zone.now - @relevant_timestamps.min) / 60).ceil
      timestamps = @record_timestamps.transform_values { |v| v.max }
      @shots.download(minutes:, timestamps:)

      raise LastTransactionMismatchError if @airtable_info.reload.last_transaction.to_i != @last_transaction

      @airtable_info.update!(
        last_transaction: @payloads.pluck("baseTransactionNumber").max,
        last_cursor: @webhook_payloads["cursor"]
      )
    end
  end
end
