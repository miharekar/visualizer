class TagCleanerJob < ApplicationJob
  queue_as :low

  def perform
    Tag.where.not(id: ShotTag.select(:tag_id)).delete_all
  end
end
