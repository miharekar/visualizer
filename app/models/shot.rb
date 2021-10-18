# frozen_string_literal: true

class Shot < ApplicationRecord
  extend Memoist
  include CloudinaryHelper

  JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
  DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_resistance espresso_resistance_weight espresso_state_change].freeze
  EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze

  belongs_to :user, optional: true

  scope :visible, -> { includes(:user).where(users: {public: true}) }
  scope :with_avatars, -> { includes(user: {avatar_attachment: :blob}) }
  scope :by_start_time, -> { order(start_time: :desc) }

  after_create :ensure_screenshot

  after_destroy_commit -> { broadcast_remove_to user }

  validates :start_time, :data, :sha, presence: true

  def self.from_file(user, file)
    return if file.blank?

    parsed_shot = ShotParser.new(File.read(file))
    shot = find_or_initialize_by(user: user, sha: parsed_shot.sha)
    %i[profile_title start_time timeframe data extra profile_fields].each do |m|
      shot.public_send("#{m}=", parsed_shot.public_send(m))
    end
    shot.extract_fields_from_extra
    shot
  end

  def extract_fields_from_extra
    EXTRA_DATA_METHODS.each do |attr|
      public_send("#{attr}=", extra[attr].presence)
    end
    self.bean_weight = extra.slice("DSx_bean_weight", "grinder_dose_weight", "bean_weight").values.find { |v| v.to_i.positive? }
  end

  def fahrenheit?
    extra["enable_fahrenheit"].to_i == 1
  end

  memoize def extra
    super.presence || {}
  end

  memoize def duration
    index = [data["espresso_flow"].size, timeframe.size].min
    timeframe[index - 1].to_f
  end

  def profile_tcl
    return if profile_fields.blank?

    content = profile_fields.except("json").to_a.sort_by(&:first).map do |k, v|
      v = "#{v} from Visualizer" if k == "profile_title"
      v = "#{v}\n\nDownloaded from Visualizer" if k == "profile_notes"
      v = "{}" if v.blank?
      v = "{#{v}}" if /\w\s\w/.match?(v)

      "#{k} #{v}"
    end

    file_from_content(["#{profile_title} from Visualizer", ".tcl"], content.join("\n"))
  end

  def profile_json
    return if profile_fields.blank? || profile_fields["json"].blank?

    json = {}
    JSON_PROFILE_KEYS.each do |key|
      json[key] = profile_fields["json"][key]
    end

    file_from_content(["#{profile_title} from Visualizer", ".json"], JSON.pretty_generate(json))
  end

  def screenshot?
    s3_etag.present? || cloudinary_id.present?
  end

  def screenshot_url
    if s3_etag.present?
      "#{ENV['BUCKET_URL']}/screenshots/#{id}.png"
    elsif cloudinary_id.present?
      cl_image_path(cloudinary_id)
    end
  end

  def ensure_screenshot
    return if screenshot?

    ScreenshotTakerJob.perform_later(self)
  end

  private

  def file_from_content(filename, content)
    file = Tempfile.new(filename)
    file.write(content)
    file.close
    file.path
  end
end

# == Schema Information
#
# Table name: shots
#
#  id                 :uuid             not null, primary key
#  bean_brand         :string
#  bean_notes         :text
#  bean_type          :string
#  bean_weight        :string
#  data               :jsonb
#  drink_ey           :string
#  drink_tds          :string
#  drink_weight       :string
#  espresso_enjoyment :integer
#  espresso_notes     :text
#  extra              :jsonb
#  grinder_model      :string
#  grinder_setting    :string
#  profile_fields     :jsonb
#  profile_title      :string
#  roast_date         :string
#  roast_level        :string
#  s3_etag            :string
#  sha                :string
#  start_time         :datetime
#  timeframe          :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  cloudinary_id      :string
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_sha      (sha)
#  index_shots_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
