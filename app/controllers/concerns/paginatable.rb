module Paginatable
  def paginate_with_cursor(scope, items: 20, before: nil, by: :id)
    scope = scope.where(by => ..before) if before.present?
    records = scope.reorder(by => :desc).limit(items + 1).to_a
    cursor = records.pop.public_send(by) if records.size > items
    cursor = cursor.strftime("%Y-%m-%dT%H:%M:%S.%6N%:z") if cursor.respond_to?(:strftime)

    [records, cursor]
  end
  end
end
