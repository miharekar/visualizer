module Paginatable
  def paginate_with_cursor(scope, by:, items: 20, cursor: params)
    before = cursor[:before]
    before_id = cursor[:before_id]
    if before.present?
      raise ActionController::BadRequest, "Invalid cursor" unless before.is_a?(String) && (before_id.nil? || before_id.is_a?(String) && before_id.match?(ApplicationRecord::UUID_PATTERN))

      value = Time.iso8601(before)
      column = scope.arel_table[by]
      if before_id.present?
        scope = scope.where(column.lt(value).or(column.eq(value).and(scope.arel_table[:id].lt(before_id))))
      else
        scope = scope.where(column.lteq(value))
      end
    end
    records = scope.reorder(by => :desc, id: :desc).limit(items + 1).to_a
    if records.size > items
      records.pop
      next_cursor = {before: records.last.public_send(by).utc.iso8601(6), before_id: records.last.id}
    end

    [records, next_cursor]
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
