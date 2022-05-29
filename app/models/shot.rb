# frozen_string_literal: true

class Shot < ApplicationRecord
  extend Memoist

  SCREENSHOTS_URL = "https://visualizer-coffee-shots.s3.eu-central-1.amazonaws.com"
  JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
  DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_resistance espresso_resistance_weight espresso_state_change].freeze
  EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze

  belongs_to :user, optional: true
  belongs_to :coffee_bag, optional: true
  has_many :shared_shots, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [1000, 500]
  end

  scope :visible, -> { joins(:user).where(users: {public: true}) }
  scope :visible_or_owned_by_id, ->(user_id) { joins(:user).where(users: {public: true}).or(where(user_id:)) }
  scope :by_start_time, -> { order(start_time: :desc) }
  scope :premium, -> { where(created_at: ..1.month.ago) }
  scope :non_premium, -> { where(created_at: 1.month.ago..) }

  after_create :ensure_screenshot

  after_destroy_commit -> { broadcast_remove_to user }

  validates :start_time, :data, :sha, presence: true

  def self.from_file(user, file)
    return if file.blank?

    parsed_shot = ShotParser.new(File.read(file))
    shot = find_or_initialize_by(user:, sha: parsed_shot.sha)
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
    self.barista = extra["my_name"].presence
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

  memoize def profile_fields
    super.presence || {}
  end

  memoize def tcl_profile_fields
    profile_fields.except("json")
  end

  memoize def json_profile_fields
    profile_fields["json"]
  end

  def tcl_profile
    return if tcl_profile_fields.blank?

    content = tcl_profile_fields.to_a.sort_by(&:first).map do |k, v|
      v = "Visualizer/#{v}" if k == "profile_title"
      v = "#{v}\n\nDownloaded from Visualizer" if k == "profile_notes"
      v = "{}" if v.blank?
      v = "{#{v}}" if /\w\s\w/.match?(v)

      "#{k} #{v}"
    end

    file_from_content(["#{profile_title} from Visualizer", ".tcl"], content.join("\n"))
  end

  def json_profile
    return if json_profile_fields.blank?

    json = {}
    JSON_PROFILE_KEYS.each do |key|
      v = profile_fields["json"][key]
      v = "Visualizer/#{v}" if key == "title"
      v = "#{v}\n\nDownloaded from Visualizer" if key == "notes"
      json[key] = v
    end

    JSON.pretty_generate(json)
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
#  barista            :string
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
#  coffee_bags_id     :uuid
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_coffee_bags_id  (coffee_bags_id)
#  index_shots_on_sha             (sha)
#  index_shots_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (coffee_bags_id => coffee_bags.id)
#  fk_rails_...  (user_id => users.id)
#
