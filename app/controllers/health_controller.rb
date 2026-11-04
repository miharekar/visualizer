class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    head :ok
  rescue ActiveRecord::ActiveRecordError
    head :service_unavailable
  end
end
