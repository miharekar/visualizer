namespace :rich_text do
  desc "Enqueue the resumable legacy note backfill"
  task backfill: :environment do
    RichTextBackfillJob.perform_later
  end
end
