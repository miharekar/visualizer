# frozen_string_literal: true

module CursorPaginatable
  def paginate_with_cursor(relation, items: 20, before: nil, by: :id, direction: :desc)
    relation = relation.where(by => ..before) if before.present?
    relation = relation.order(by => direction).limit(items + 1).load
    cursor = relation.last.public_send(by) if relation.size > items

    [relation.take(items), cursor]
  end
end
