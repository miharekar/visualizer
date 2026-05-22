class OptExistingUsersOutOfShotUploadedEmail < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE users
      SET unsubscribed_from = (
        SELECT jsonb_agg(DISTINCT notification)
        FROM jsonb_array_elements_text(COALESCE(unsubscribed_from, '[]'::jsonb) || '["shot_uploaded"]'::jsonb) AS notification
      )
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE users
      SET unsubscribed_from = COALESCE(unsubscribed_from, '[]'::jsonb) - 'shot_uploaded'
    SQL
  end
end
