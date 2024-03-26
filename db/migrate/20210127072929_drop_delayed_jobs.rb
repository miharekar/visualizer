class DropDelayedJobs < ActiveRecord::Migration[6.1]
  def up
    drop_table :delayed_jobs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
