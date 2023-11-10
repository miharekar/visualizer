# frozen_string_literal: true

require "ruby-vips"

class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(blob, options)
    blob.variant(options).processed
  rescue Vips::Error => e
    Appsignal.send_error(e) do |transaction|
      transaction.set_tags(blob_id: blob.id, attachments: blob.attachments.map { |a| a.record.to_global_id.to_s })
    end
    blob.attachments.each { |a| a.purge_later }
  end
end
