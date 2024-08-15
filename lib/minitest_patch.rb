# minitest 5.25 has a new API for `with_info_handler`
# https://github.com/rails/rails/commit/002519a5faf4e10d0bcd737bde9f7e6a9d831024
# https://github.com/rails/rails/blob/main/activesupport/lib/active_support/testing/parallelization/worker.rb

raise unless Rails.version == "7.2.0"

module ActiveSupport
  module Testing
    class Parallelization
      class Worker
        def perform_job(job)
          klass    = job[0]
          method   = job[1]
          reporter = job[2]

          set_process_title("#{klass}##{method}")

          result = nil

          # TODO: Remove conditional when we support on minitest 5.25+
          if klass.method(:with_info_handler).arity == 2
            t0 = nil

            handler = lambda do
              unless reporter.passed? then
                warn "Current results:"
                warn reporter.reporters.grep(SummaryReporter).first
              end

              warn "Current: %s#%s %.2fs" % [klass, method, Minitest.clock_time - t0]
            end

            result = klass.with_info_handler reporter, handler do
              t0 = Minitest.clock_time
              Minitest.run_one_method(klass, method)
            end
          else
            result = klass.with_info_handler reporter do
              Minitest.run_one_method(klass, method)
            end
          end

          safe_record(reporter, result)
        end
      end
    end
  end
end

class MinitestPatch
  # make Zeitwerk happy
end
