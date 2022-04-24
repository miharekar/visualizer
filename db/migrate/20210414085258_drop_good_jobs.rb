# frozen_string_literal: true

class DropGoodJobs < ActiveRecord::Migration[6.1]
  def up
    drop_table :good_jobs
  end
end
