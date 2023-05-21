# frozen_string_literal: true

require "ruby-vips"

class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(blob, options)
    blob.variant(options).process
  rescue Vips::Error => e
    RorVsWild.record_error(e, blob_id: blob.id, attachments: blob.attachments.map { |a| a.record.to_global_id.to_s })
    blob.attachments.each { |a| a.purge_later }
  end
end
