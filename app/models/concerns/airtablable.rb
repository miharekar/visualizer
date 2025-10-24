module Airtablable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_airtable_sync

    after_save_commit :sync_to_airtable
    after_destroy_commit :cleanup_airtable
  end

  class_methods do
    def airtable_class
      "Airtable::#{name.pluralize}".constantize
    end
  end

  private

  def sync_to_airtable
    return if skip_airtable_sync || !user.has_airtable?

    AirtableUploadRecordJob.perform_later(self)
  end

  def cleanup_airtable
    return if airtable_id.blank? || !user.has_airtable?

    AirtableDeleteRecordJob.perform_later(self.class.airtable_class, user, airtable_id)
  end
end
