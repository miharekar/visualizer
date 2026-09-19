class JournalColumnsController < ApplicationController
  before_action :require_authentication

  def update
    settings = params[:reset].present? ? nil : {"order" => params.fetch(:order, []), "hidden" => params.fetch(:hidden, [])}
    journal.save_columns(settings)
    redirect_to shots_path(format: :html), status: :see_other
  rescue Journal::InvalidChange, ActiveRecord::RecordInvalid => error
    redirect_to shots_path(format: :html), status: :see_other, alert: error.message
  end
end
