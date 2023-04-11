# frozen_string_literal: true

class Shot < ApplicationRecord
  include Rails.application.routes.url_helpers

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

  after_create :ensure_screenshot

  after_destroy_commit -> { broadcast_remove_to user, :shots }

  validates :start_time, :information, :sha, presence: true

  def self.from_file(user, file)
    return if file.blank?

    Parsers::Base.parse(File.read(file)).build_shot(user)
  end

  def self.airtable_fields
    [
      {name: "ID", type: "singleLineText"},
      {name: "URL", type: "url"},
      {name: "Espresso enjoyment", type: "rating", options: {max: 10, icon: "star", color: "yellowBright"}},
      {name: "Profile title", type: "singleLineText"},
      {name: "Start time", type: "dateTime", options: {timeZone: "client", dateFormat: {name: "local"}, timeFormat: {name: "24hour"}}},
      {name: "Duration", type: "duration", options: {durationFormat: "h:mm:ss.SS"}},
      {name: "Barista", type: "singleLineText"},
      {name: "Bean weight", type: "singleLineText"},
      {name: "Drink weight", type: "singleLineText"},
      {name: "Grinder model", type: "singleLineText"},
      {name: "Grinder setting", type: "singleLineText"},
      {name: "Bean brand", type: "singleLineText"},
      {name: "Bean type", type: "singleLineText"},
      {name: "Roast date", type: "singleLineText"},
      {name: "Roast level", type: "singleLineText"},
      {name: "Drink TDS", type: "singleLineText"},
      {name: "Drink EY", type: "singleLineText"},
      {name: "Bean notes", type: "richText"},
      {name: "Notes", type: "richText"},
      {name: "Private notes", type: "richText"},
      {name: "Image", type: "multipleAttachments"}
    ]
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

  def for_airtable
    fields = {
      "ID" => id,
      "URL" => shot_url(self),
      "Profile title" => profile_title,
      "Start time" => start_time,
      "Duration" => duration.round,
      "Barista" => barista,
      "Bean weight" => bean_weight,
      "Drink weight" => drink_weight,
      "Grinder model" => grinder_model,
      "Grinder setting" => grinder_setting,
      "Bean brand" => bean_brand,
      "Bean type" => bean_type,
      "Roast date" => roast_date,
      "Roast level" => roast_level,
      "Drink TDS" => drink_tds,
      "Drink EY" => drink_ey,
      "Bean notes" => bean_notes,
      "Notes" => espresso_notes,
      "Private notes" => private_notes
    }

    fields["Espresso enjoyment"] = (espresso_enjoyment / 10.0).round if espresso_enjoyment.present? && espresso_enjoyment.positive?
    fields["Image"] = [{url: image.url(disposition: "attachment"), filename: image.filename.to_s}] if image.attached?
    {fields:}
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
#  private_notes      :text
#  profile_title      :string
#  roast_date         :string
#  roast_level        :string
#  s3_etag            :string
#  sha                :string
#  start_time         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_created_at              (created_at)
#  index_shots_on_sha                     (sha)
#  index_shots_on_user_id_and_created_at  (user_id,created_at)
#  index_shots_on_user_id_and_start_time  (user_id,start_time)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
