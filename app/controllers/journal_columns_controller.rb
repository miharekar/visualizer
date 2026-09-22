class JournalColumnsController < ApplicationController
  before_action :require_authentication

  def update
    query = params.permit(query: %i[q coffee_bag tags]).to_h.fetch("query", {})
    settings = params[:reset].present? ? nil : params.fetch(:columns, [])
    journal.save_columns(settings)
    redirect_to shots_path(**query, format: :html), status: :see_other
  rescue Journal::InvalidChange, ActiveRecord::RecordInvalid => error
    redirect_to shots_path(**query, format: :html), status: :see_other, alert: error.message
  end
end
