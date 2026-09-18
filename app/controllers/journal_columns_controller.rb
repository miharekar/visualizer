class JournalColumnsController < ApplicationController
  before_action :require_authentication

  def update
    settings = (params.key?(:columns) && params[:columns].nil?) ? nil : params.expect(columns: {}).to_h
    journal = Journal.new(Current.user)
    journal.save_columns(settings)
    if settings.nil?
      render json: {order: journal.ordered_columns, visible: journal.visible_columns}
    else
      head :no_content
    end
  rescue Journal::InvalidChange => error
    render json: {error: error.message}, status: :unprocessable_content
  end
end
