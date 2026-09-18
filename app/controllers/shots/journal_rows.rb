module Shots
  module JournalRows
    private

    def journal_rows(shots)
      @journal.scope.where(id: shots.map(&:id)).with_notes.includes(:tags, :information).map do |shot|
        {id: shot.id, html: render_to_string(partial: "journals/row", formats: [:html], locals: {shot:, columns: @journal.ordered_columns, visible_columns: @journal.visible_columns})}
      end
    end
  end
end
