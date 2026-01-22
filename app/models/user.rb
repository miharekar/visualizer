class User < ApplicationRecord
  include Sluggable
  slug_from :name

  has_secure_password

  EMAIL_NOTIFICATIONS = %w[yearly_brew newsletter].freeze
  DATE_FORMATS = {
    "dd.mm.yyyy" => "%d.%m.%Y",
    "mm.dd.yyyy" => "%m.%d.%Y",
    "yyyy.mm.dd" => "%Y.%m.%d"
  }.freeze

  has_many :sessions, dependent: :destroy
  has_many :shots, dependent: :nullify
  has_many :shared_shots, dependent: :nullify
  has_many :identities, dependent: :destroy
  has_many :oauth_applications, class_name: "Doorkeeper::Application", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", foreign_key: :resource_owner_id, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :access_tokens, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :roasters, dependent: :destroy
  has_many :coffee_bags, through: :roasters
  has_many :tags, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy
  has_many :dropdown_values, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [96, 96], format: :jpeg, saver: {strip: true}
  end

  validates :email, presence: true, uniqueness: true, format: {with: /\A.*@.*\z/, message: "must be valid"}
  validates :password, length: {minimum: 8}, if: :password_digest_changed?
  validates :name, presence: true, if: :public?
  validates :lemon_squeezy_customer_id, uniqueness: true, allow_blank: true
  validates :creem_customer_id, uniqueness: true, allow_blank: true

  before_validation :set_webauthn_id
  after_update_commit :reflect_public_to_shots, if: -> { saved_change_to_public? }
  after_update_commit :update_coffee_management, if: -> { saved_change_to_coffee_management_enabled? }
  after_update_commit :update_date_format_on_shots, if: -> { coffee_management_enabled? && saved_change_to_date_format? }

  generates_token_for :unsubscribe

  scope :visible, -> { where(public: true) }
  scope :visible_or_id, ->(id) { id ? where(public: true).or(where(id:)) : where(public: true) }
  scope :order_by_name, -> { order("LOWER(name)") }

  normalizes :email, with: ->(e) { e.strip.downcase }

  def self.admin
    where(admin: true).first
  end

  def self.unsubscribe_by_token!(token)
    token_definition = token_definitions[:unsubscribe]
    payload = token_definition.message_verifier.verified(token, purpose: token_definition.full_purpose)
    return unless payload && payload["id"].present? && payload["notification"].present?

    user = find_by(id: payload["id"])
    return unless user

    unsubscribed_from = (user.unsubscribed_from + [payload["notification"]]).uniq
    user.update!(unsubscribed_from:)
    payload["notification"]
  end

  def display_name
    name.presence || email
  end

  def gravatar_url
    hash = Digest::MD5.hexdigest(email.to_s.downcase)
    "https://www.gravatar.com/avatar/#{hash}.jpg"
  end

  def chart_settings
    super if premium?
  end

  def premium?
    premium_expires_at&.future? || supporter
  end

  def has_airtable?
    premium? && identities.by_provider(:airtable).exists?
  end

  def coffee_management_enabled?
    premium? && coffee_management_enabled
  end

  def can_manage_premium?
    creem_customer_id.present? || lemon_squeezy_customer_id.present?
  end

  def wants_fahrenheit?
    temperature_unit == "Fahrenheit"
  end

  def metadata_fields
    super.presence || []
  end

  def unsubscribed_from
    super.presence || []
  end

  def communication
    super.presence || []
  end

  def notify?(notification)
    unsubscribed_from.exclude?(notification.to_s)
  end

  def unsubscribe_token_for(notification)
    token_definition = self.class.token_definitions[:unsubscribe]
    token_definition.message_verifier.generate({id:, notification:}, purpose: token_definition.full_purpose)
  end

  def date_format
    super.presence || "dd.mm.yyyy"
  end

  def date_format_string
    DATE_FORMATS[date_format]
  end

  private

  def set_webauthn_id
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def generate_slug
    super if public?
  end

  def reflect_public_to_shots
    shots.update_all(public:) # rubocop:disable Rails/SkipsModelValidations
  end

  def update_coffee_management
    roasters.destroy_all
    return unless coffee_management_enabled?

    EnableCoffeeManagementJob.perform_later(self)
  end

  def update_date_format_on_shots
    ActiveJob.perform_all_later(coffee_bags.pluck(:id).map { |id| RefreshCoffeeBagFieldsOnShotsJob.new(CoffeeBag.new(id:)) })
  end
end

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                        :uuid             not null, primary key
#  admin                     :boolean          default(FALSE), not null
#  beta                      :boolean          default(FALSE), not null
#  chart_settings            :jsonb
#  coffee_management_enabled :boolean          default(FALSE), not null
#  communication             :jsonb
#  date_format               :string
#  decent_email              :string
#  decent_token              :string
#  developer                 :boolean          default(FALSE), not null
#  email                     :string           default(""), not null
#  github                    :string
#  hide_shot_times           :boolean          default(FALSE), not null
#  last_read_change          :datetime
#  metadata_fields           :jsonb
#  name                      :string
#  password_digest           :string           default(""), not null
#  premium_expires_at        :datetime
#  public                    :boolean          default(FALSE), not null
#  skin                      :string
#  slug                      :string
#  supporter                 :boolean          default(FALSE), not null
#  temperature_unit          :string
#  timezone                  :string
#  unsubscribed_from         :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  creem_customer_id         :string
#  lemon_squeezy_customer_id :string
#  stripe_customer_id        :string
#  webauthn_id               :string
#
# Indexes
#
#  index_users_on_creem_customer_id          (creem_customer_id) UNIQUE
#  index_users_on_email                      (email) UNIQUE
#  index_users_on_lemon_squeezy_customer_id  (lemon_squeezy_customer_id) UNIQUE
#  index_users_on_slug                       (slug) UNIQUE
#
