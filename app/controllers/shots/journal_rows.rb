module Shots
  module JournalRows
    private

    def journal_response(shots, action: :replace, fields: nil, count: nil, matches: true)
      shots = shots.to_a
      render_id = SecureRandom.uuid
      stream = render_to_string(partial: "journals/updates", formats: [:turbo_stream], locals: {shots:, action:, fields:, count:, matches:, render_id:})
      {rows: shots.map { {id: it.id} }, stream:, render_id:, count:, matches:}.compact
    end
  end
end
