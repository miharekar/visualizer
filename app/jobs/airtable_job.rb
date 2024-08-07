class AirtableJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, attempts: 2

  rescue_from Airtable::DataError do |airtable_error|
    if airtable_error.matches_error_type?("RATE_LIMIT_REACHED") && executions < 5
      delay = executions**4
      delay_jitter = determine_jitter_for_delay(delay, self.class.retry_jitter)
      wait = delay + delay_jitter + 1.minute
      retry_job(wait:, queue: :low)
    else
      Appsignal.report_error(airtable_error)
    end
  end
end
