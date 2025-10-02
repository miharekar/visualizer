module CursorPaginatable
  def paginate_with_cursor(relation, items: 20, before: nil, by: :id)
    relation = relation.where(by => ..before) if before.present?
    relation = relation.reorder(by => :desc).limit(items + 1).to_a
    cursor = relation.pop.public_send(by) if relation.size > items
    cursor = cursor.strftime("%Y-%m-%dT%H:%M:%S.%6N%:z") if cursor.respond_to?(:strftime)

    [relation, cursor]
  end
end
