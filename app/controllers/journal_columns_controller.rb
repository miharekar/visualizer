class JournalColumnsController < ApplicationController
  before_action :require_authentication

  def update
    settings = (params.key?(:columns) && params[:columns].nil?) ? nil : params.expect(columns: {}).to_h
    Current.journal.save_columns(settings)
    if settings.nil?
      render json: {order: Current.journal.ordered_columns, visible: Current.journal.visible_columns}
    else
      head :no_content
    end
  rescue Journal::InvalidChange => error
    render json: {error: error.message}, status: :unprocessable_content
  end
end
