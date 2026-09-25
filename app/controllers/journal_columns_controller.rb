class JournalColumnsController < ApplicationController
  before_action :require_authentication
  before_action :require_journal

  def update
    query = params.permit(query: %i[q coffee_bag tags]).to_h.fetch("query", {}).compact_blank
    journal.save_columns(params.fetch(:columns, []))
    redirect_to shots_path(**query, format: :html), status: :see_other
  rescue Journal::InvalidChange, ActiveRecord::RecordInvalid => error
    redirect_to shots_path(**query, format: :html), status: :see_other, alert: error.message
  end
end
