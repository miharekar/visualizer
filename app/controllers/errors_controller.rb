class ErrorsController < ApplicationController
  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def service_unavailable
    render status: :service_unavailable
  end
end
