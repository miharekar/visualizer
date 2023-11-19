# frozen_string_literal: true

module CursorPaginatable
  def paginate_with_cursor(relation, items: 20, by: :id, before: nil)
    relation = relation.where(by => ..before) if before.present?
    relation = relation.order(by => :desc).limit(items + 1).load
    cursor = relation.last.start_time if relation.size > items

    [relation.take(items), cursor]
  end
end
