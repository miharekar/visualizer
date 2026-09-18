class JournalsController < ApplicationController
  include Shots::JournalRows
  before_action :require_authentication
  before_action :set_journal

  rescue_from Journal::InvalidChange, ActiveRecord::RecordInvalid do |error|
    render json: {error: error.message}, status: :unprocessable_content
  end
  rescue_from Journal::Conflict do |error|
    render json: {error: error.message}, status: :conflict
  end
  rescue_from ActiveRecord::RecordNotFound do
    render json: {error: "Shot or coffee not available"}, status: :not_found
  end

  def update
    if params[:undo].present?
      shots = @journal.undo(params[:undo])
      render json: {rows: journal_rows(shots)}
    else
      changes = params[:changes]
      changes = changes.map { it.is_a?(ActionController::Parameters) ? it.to_unsafe_h : it } if changes.is_a?(Array)
      shots, undo = @journal.update(changes)
      render json: {rows: journal_rows(shots), undo:}
    end
  end

  private

  def set_journal
    @journal = Journal.new(Current.user)
  end
end
