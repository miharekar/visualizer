module Paginatable
  def paginate_with_cursor(scope, items: 20, before: nil, before_id: nil, by: :id)
    if before.present?
      raise ActionController::BadRequest, "Invalid cursor" unless before.is_a?(String) && (before_id.nil? || before_id.is_a?(String) && before_id.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i))

      value = by == :id ? before : Time.iso8601(before)
      column = scope.arel_table[by]
      if before_id.present?
        scope = scope.where(column.lt(value).or(column.eq(value).and(scope.arel_table[:id].lt(before_id))))
      else
        # Legacy links point at the first omitted timestamp, so include its ties.
        scope = scope.where(column.lteq(value))
      end
    end
    records = scope.reorder(by => :desc, id: :desc).limit(items + 1).to_a
    if records.size > items
      records.pop
      value = records.last.public_send(by)
      cursor = {before: value.respond_to?(:iso8601) ? value.utc.iso8601(6) : value, before_id: records.last.id}
    end

    [records, cursor]
  rescue ArgumentError
    raise ActionController::BadRequest, "Invalid cursor"
  end

  def paginate_with_offset(scope, items: 20, offset:)
    records = scope.order(:id).limit(items + 1).offset(offset)
    if records.size > items
      new_offset = offset + items
      records = records.first(items)
    end
    [records, new_offset]
  end
end
