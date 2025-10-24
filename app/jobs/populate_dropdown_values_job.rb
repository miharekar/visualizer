class PopulateDropdownValuesJob < ApplicationJob
  queue_as :low

  def perform(user: nil)
    if user
      populate_dropdown_values(user)
    else
      User.find_each { |user| populate_dropdown_values(user) }
    end
  end

  private

  def populate_dropdown_values(user)
    created_at = updated_at = Time.current

    DropdownValue.transaction do
      DropdownValue::VALID_KINDS.each do |kind|
        unique_values = user.shots.distinct.pluck(kind).compact_blank
        existing_values = DropdownValue.where(user:, kind:).pluck(:value)
        new_values = unique_values - existing_values
        rows = new_values.map { |value| {user_id: user.id, kind:, value:, created_at:, updated_at:} }
        DropdownValue.insert_all(rows, unique_by: %i[user_id kind value]) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
