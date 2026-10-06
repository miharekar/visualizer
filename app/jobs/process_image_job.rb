class ProcessImageJob < ApplicationJob
  queue_as :low
  retry_on HotCell::TransientFailure, wait: :polynomially_longer, attempts: 10

  def perform(blob, options)
    blob.variant(options).processed
  rescue HotCell::PermanentFailure => e
    Appsignal.report_error(e) do
      it.set_tags(blob_id: blob.id, attachments: blob.attachments.map { it.record.to_global_id.to_s })
    end
    blob.attachments.each(&:purge_later)
  end
end
