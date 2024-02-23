# frozen_string_literal: true

class Shot < ApplicationRecord
  include ShotPresenter

  LIST_ATTRIBUTES = %i[id start_time profile_title user_id bean_weight drink_weight drink_tds drink_tds drink_ey espresso_enjoyment barista bean_brand bean_type duration grinder_model grinder_setting].freeze

  belongs_to :user, optional: true, touch: true
  has_one :information, class_name: "ShotInformation", dependent: :destroy, inverse_of: :shot
  has_many :shared_shots, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [1000, 500]
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :visible, -> { where(public: true) }
  scope :visible_or_owned_by_id, ->(user_id) { user_id ? visible.or(where(user_id:)) : visible }
  scope :for_list, -> { select(LIST_ATTRIBUTES) }
  scope :by_start_time, -> { order(start_time: :desc) }
  scope :premium, -> { where(created_at: ..1.month.ago) }
  scope :non_premium, -> { where(created_at: 1.month.ago..) }

  attr_accessor :skip_airtable_sync

  after_create :ensure_screenshot
  after_save_commit :sync_to_airtable
  after_destroy_commit :cleanup_airtable

  validates :start_time, :sha, presence: true

  broadcasts_to ->(shot) { [shot.user, :shots] }, inserts_by: :prepend

  def self.from_file(user, file_content)
    return Shot.new if file_content.blank?

    Parsers::Base.parser_for(file_content).build_shot(user)
  end

  def metadata
    super.presence || {}
  end

  def related_shots(limit: 5)
    query = self.class.where(user:).where.not(id:).limit(limit)
    query.where(start_time: start_time..).order(:start_time) + [self] + query.where(start_time: ..start_time).order(start_time: :desc)
  end

  def screenshot?
    s3_etag.present?
  end

  def ensure_screenshot
    return if screenshot? || Rails.env.local?

    ScreenshotTakerJob.perform_later(self)
  end

  def sync_to_airtable
    return if skip_airtable_sync || !user.premium? || user.identities.by_provider(:airtable).empty?

    AirtableShotUploadJob.perform_later(self)
  end

  def cleanup_airtable
    return if airtable_id.blank? || !user.premium? || user.identities.by_provider(:airtable).empty?

    AirtableShotDeleteJob.perform_later(user, airtable_id)
  end
end

# == Schema Information
#
# Table name: shots
#
#  id                 :uuid             not null, primary key
#  barista            :string
#  bean_brand         :string
#  bean_notes         :text
#  bean_type          :string
#  bean_weight        :string
#  drink_ey           :string
#  drink_tds          :string
#  drink_weight       :string
#  duration           :float
#  espresso_enjoyment :integer
#  espresso_notes     :text
#  grinder_model      :string
#  grinder_setting    :string
#  metadata           :jsonb
#  private_notes      :text
#  profile_title      :string
#  public             :boolean
#  roast_date         :string
#  roast_level        :string
#  s3_etag            :string
#  sha                :string
#  start_time         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  airtable_id        :string
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_airtable_id  (airtable_id)
#  index_shots_on_created_at   (created_at)
#  index_shots_on_sha          (sha)
#  index_shots_on_start_time   (start_time)
#  index_shots_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
