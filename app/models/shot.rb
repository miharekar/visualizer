# frozen_string_literal: true

class Shot < ApplicationRecord
  SCREENSHOTS_URL = "https://visualizer-coffee-shots.s3.eu-central-1.amazonaws.com"
  DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_state_change].freeze
  EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze

  belongs_to :user, optional: true, touch: true
  has_one :information, class_name: "ShotInformation", dependent: :destroy
  has_many :shared_shots, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [1000, 500]
  end

  scope :visible, -> { where(user_id: User.where(public: true).select(:id)) }
  scope :visible_or_owned_by_id, ->(user_id) { visible.or(where(user_id:)) }
  scope :by_start_time, -> { order(start_time: :desc) }
  scope :premium, -> { where(created_at: ..1.month.ago) }
  scope :non_premium, -> { where(created_at: 1.month.ago..) }

  attr_accessor :skip_airtable_sync

  after_create :ensure_screenshot
  after_save_commit :sync_to_airtable
  after_destroy_commit :broadcast_and_cleanup_airtable

  validates :start_time, :information, :sha, presence: true

  def self.from_file(user, file_content)
    return Shot.new if file_content.blank?

    Parsers::Base.parse(file_content).build_shot(user)
  end

  def metadata
    super.presence || {}
  end

  def related_shots(limit: 5)
    query = self.class.where(user:).where.not(id:).limit(limit)
    query.where(start_time: start_time..).order(:start_time) + [self] + query.where(start_time: ..start_time).order(start_time: :desc)
  end

  def extract_fields_from_extra
    EXTRA_DATA_METHODS.each do |attr|
      public_send("#{attr}=", information.extra[attr].presence)
    end
    self.bean_weight = information.extra.slice("DSx_bean_weight", "grinder_dose_weight", "bean_weight").values.find { |v| v.to_i.positive? }
    self.barista = information.extra["my_name"].presence
  end

  def screenshot?
    s3_etag.present?
  end

  def screenshot_url
    "#{SCREENSHOTS_URL}/screenshots/#{id}.png" if screenshot?
  end

  def ensure_screenshot
    return if screenshot?

    ScreenshotTakerJob.perform_later(self)
  end

  def sync_to_airtable
    return if skip_airtable_sync || !user.premium? || user.identities.by_provider(:airtable).empty?

    AirtableShotUploadJob.perform_later(self)
  end

  def broadcast_and_cleanup_airtable
    broadcast_remove_to(user, :shots)
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
#  index_shots_on_airtable_id             (airtable_id)
#  index_shots_on_created_at              (created_at)
#  index_shots_on_sha                     (sha)
#  index_shots_on_user_id_and_created_at  (user_id,created_at)
#  index_shots_on_user_id_and_start_time  (user_id,start_time)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
