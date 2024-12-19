class Shot < ApplicationRecord
  include ShotPresenter
  include Airtablable
  include Jsonable
  include DateParseable

  DAILY_LIMIT = 50
  LIST_ATTRIBUTES = %i[id coffee_bag_id start_time profile_title user_id bean_weight drink_weight drink_tds drink_tds drink_ey espresso_enjoyment barista bean_brand bean_type duration grinder_model grinder_setting roast_level roast_date].freeze

  before_validation :refresh_coffee_bag_fields, if: -> { coffee_bag_id_changed? }

  belongs_to :user, optional: true, touch: true
  belongs_to :coffee_bag, optional: true
  has_one :information, class_name: "ShotInformation", dependent: :destroy, inverse_of: :shot
  has_many :shared_shots, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [1000, 500]
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :visible, -> { where(public: true) }
  scope :visible_or_owned_by_id, ->(user_id) { user_id ? visible.or(where(user_id:)) : visible }
  scope :for_list, -> { select(LIST_ATTRIBUTES).includes(coffee_bag: :roaster) }
  scope :by_start_time, -> { order(start_time: :desc) }
  scope :premium, -> { where(created_at: ..1.month.ago) }
  scope :non_premium, -> { where(created_at: 1.month.ago..) }

  validates :start_time, :sha, :user, presence: true
  validate :daily_limit, on: :create

  broadcasts_to ->(shot) { [shot.user, :shots] }, inserts_by: :prepend

  def self.from_file(user, file_content)
    return Shot.new(user:) if file_content.blank?

    Parsers::Base.parser_for(file_content).build_shot(user)
  end

  def metadata
    super.presence || {}
  end

  def refresh_coffee_bag_fields
    self.bean_brand = coffee_bag&.roaster&.name
    self.bean_type = coffee_bag&.name
    self.roast_date = coffee_bag&.roast_date&.strftime(user.date_format_string)
    self.roast_level = coffee_bag&.roast_level
  end

  def related_shots(limit: 15)
    query = self.class.where(user:).where.not(id:).limit(limit)
    query.where(start_time: start_time..).order(:start_time) + [self] + query.where(start_time: ..start_time).order(start_time: :desc)
  end

  def parsed_roast_date
    date_format_string = user&.date_format_string || User::DATE_FORMATS["dd.mm.yyyy"]
    parse_date(roast_date, date_format_string)
  end

  def iso8601_roast_date_time
    parsed_roast_date&.strftime("%Y-%m-%dT%H:%M:%SZ")
  end

  private

  def daily_limit
    return if user.premium?
    return if self.class.where(user_id:).where("start_time > NOW() - INTERVAL '1 day'").count < DAILY_LIMIT

    errors.add(:base, :over_daily_limit, message: "You've reached your daily limit of #{DAILY_LIMIT} shots. Please consider upgrading to a premium account.")
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
#  sha                :string
#  start_time         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  airtable_id        :string
#  coffee_bag_id      :uuid
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_airtable_id    (airtable_id)
#  index_shots_on_bean_brand     (bean_brand) USING gin
#  index_shots_on_bean_type      (bean_type) USING gin
#  index_shots_on_coffee_bag_id  (coffee_bag_id)
#  index_shots_on_created_at     (created_at)
#  index_shots_on_sha            (sha)
#  index_shots_on_start_time     (start_time)
#  index_shots_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (coffee_bag_id => coffee_bags.id)
#  fk_rails_...  (user_id => users.id)
#
