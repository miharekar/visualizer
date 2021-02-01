# frozen_string_literal: true

GoodJob.retry_on_unhandled_error = false
GoodJob.on_thread_error = ->(e) { Rollbar.error(e) }
