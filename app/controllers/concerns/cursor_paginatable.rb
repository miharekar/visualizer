module CursorPaginatable
  def paginate_with_cursor(relation, items: 20, before: nil, by: :id, direction: :desc)
    relation = relation.where(by => ..before) if before.present?
    relation = relation.order(by => direction).limit(items + 1).to_a
    cursor = relation.pop.public_send(by) if relation.size > items

    [relation, cursor]
  end
end
