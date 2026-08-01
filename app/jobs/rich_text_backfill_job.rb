class RichTextBackfillJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 1_000
  SOURCES = [
    %w[shots Shot bean_notes],
    %w[shots Shot espresso_notes],
    %w[shots Shot private_notes],
    %w[coffee_bags CoffeeBag notes],
    %w[changes Update body]
  ].freeze

  def perform
    SOURCES.each { |source| backfill(source) }
  end

  private

  def backfill(source)
    table_name, record_type, attribute = source
    model = legacy_model(table_name)
    pending(model, record_type, attribute).in_batches(of: BATCH_SIZE) do |batch|
      rows = batch.filter_map { |record| rich_text_row(record, record_type, attribute) }
      ActionText::RichText.insert_all(rows, unique_by: %i[record_type record_id name]) if rows.any? # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def pending(model, record_type, attribute)
    existing = ActionText::RichText.where(record_type:, name: attribute).select(:record_id)
    model.where.not(attribute => [nil, ""]).where.not(id: existing).select(:id, attribute)
  end

  def legacy_model(table_name)
    Class.new(ActiveRecord::Base) do # rubocop:disable Rails/ApplicationRecord
      self.table_name = table_name
      self.inheritance_column = nil
    end
  end

  def rich_text_row(record, record_type, attribute)
    html = RichTextSanitizer.from_markdown(record.read_attribute(attribute)).presence
    return if html.blank? || ActionText::Content.new(html).to_plain_text.blank?

    now = Time.current
    {record_type:, record_id: record.id, name: attribute, body: html, created_at: now, updated_at: now}
  end
end
