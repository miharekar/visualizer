module Paginatable
  CURSOR_PURPOSE = "pagination cursor".freeze

  def self.encrypt_time(time)
    cursor_encryptor.encrypt_and_sign(time.utc.iso8601(6), purpose: CURSOR_PURPOSE)
  end

  def self.decrypt_time(value)
    Time.iso8601(cursor_encryptor.decrypt_and_verify(value, purpose: CURSOR_PURPOSE))
  end

  def self.cursor_encryptor
    key = Rails.application.key_generator.generate_key(CURSOR_PURPOSE, ActiveSupport::MessageEncryptor.key_len)
    ActiveSupport::MessageEncryptor.new(key, url_safe: true)
  end

  def paginate_with_cursor(scope, by:, items: 20, cursor: params)
    before = cursor[:before]
    before_id = cursor[:before_id]
    if before.present?
      raise ActionController::BadRequest, "Invalid cursor" unless before.is_a?(String) && (before_id.nil? || before_id.is_a?(String) && before_id.match?(ApplicationRecord::UUID_PATTERN))

      value = Paginatable.decrypt_time(before)
      column = scope.arel_table[by]
      scope = scope.where(column.lteq(value))
      scope = scope.where(column.lt(value).or(scope.arel_table[:id].lt(before_id))) if before_id.present?
    end
    records = scope.reorder(by => :desc, id: :desc).limit(items + 1).to_a
    if records.size > items
      records.pop
      next_cursor = {before: Paginatable.encrypt_time(records.last.public_send(by)), before_id: records.last.id}
    end

    [records, next_cursor]
  rescue ArgumentError, ActiveSupport::MessageEncryptor::InvalidMessage
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
