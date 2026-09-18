class JournalColumnsController < ApplicationController
  before_action :require_authentication

  def update
    Journal.new(Current.user).save_columns(params.expect(columns: {}).to_h)
    head :no_content
  rescue Journal::InvalidChange => error
    render json: {error: error.message}, status: :unprocessable_content
  end
end
