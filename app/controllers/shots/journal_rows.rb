module Shots
  module JournalRows
    private

    def journal_rows(shots)
      Current.journal.scope.where(id: shots.map(&:id)).with_notes.includes(:tags, :information).map do |shot|
        {id: shot.id, html: render_to_string(partial: "journals/row", formats: [:html], locals: {shot:, columns: Current.journal.ordered_columns, visible_columns: Current.journal.visible_columns})}
      end
    end
  end
end
