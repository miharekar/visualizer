# frozen_string_literal: true

namespace :cron do
  task hourly: :environment do
    SharedShotCleanupJob.perform_now
  end
end
