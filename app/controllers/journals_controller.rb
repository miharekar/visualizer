class JournalsController < ApplicationController
  before_action :require_authentication
  before_action :require_journal

  rescue_from Journal::InvalidChange, ActiveRecord::RecordInvalid do |error|
    @error = error.message
    @shots ||= []
    if action_name == "update"
      render :update, formats: :turbo_stream, status: :unprocessable_content
    else
      render :edit, status: :unprocessable_content
    end
  end
  rescue_from(ActiveRecord::RecordNotFound) { head :not_found, content_type: "text/plain" }

  def edit
    @field = params[:field]
    raise Journal::InvalidChange, "Some fields are not editable" unless journal.editable_columns.key?(@field)

    @shots = journal.shots(params[:ids], fields: [@field])
    @value = journal.editor_value(@shots, @field)
  end

  def update
    @editor = ActiveModel::Type::Boolean.new.cast(params[:editor])
    @field = params[:field].to_s
    @value = params[:value]
    @shots = journal.shots(params[:ids], fields: [@field])
    @fields = journal.update(@shots, field: @field, value: @value)
    render :update, formats: :turbo_stream
  end
end
