class User < ApplicationRecord
  include Sluggable
  slug_from :name

  EMAIL_NOTIFICATIONS = %w[yearly_brew newsletter].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable

  has_many :shots, dependent: :nullify
  has_many :shared_shots, dependent: :nullify
  has_many :identities, dependent: :destroy
  has_many :oauth_applications, class_name: "Doorkeeper::Application", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", foreign_key: :resource_owner_id, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :access_tokens, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_one :customer, dependent: :nullify

  has_one_attached :avatar, service: :cloudinary

  scope :visible, -> { where(public: true) }
  scope :visible_or_id, ->(id) { id ? where(public: true).or(where(id:)) : where(public: true) }
  scope :by_name, -> { order("LOWER(name)") }

  after_commit :reflect_public_to_shots, on: :update, if: -> { saved_change_to_public? }

  validates :name, presence: true, if: :public?

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

  def wants_fahrenheit?
    temperature_unit == "Fahrenheit"
  end

  def metadata_fields
    super.presence || []
  end

  def notify?(notification)
    unsubscribed_from.to_a.exclude?(notification.to_s)
  end

  private

  def generate_slug
    return unless public?

    super
  end

  def reflect_public_to_shots
    shots.update_all(public:)
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  admin                  :boolean
#  beta                   :boolean
#  chart_settings         :jsonb
#  decent_email           :string
#  decent_token           :string
#  developer              :boolean
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  github                 :string
#  hide_shot_times        :boolean
#  last_read_change       :datetime
#  metadata_fields        :jsonb
#  name                   :string
#  premium_expires_at     :datetime
#  public                 :boolean          default(FALSE)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  skin                   :string
#  slug                   :string
#  supporter              :boolean
#  temperature_unit       :string
#  timezone               :string
#  unsubscribed_from      :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  stripe_customer_id     :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_slug                  (slug) UNIQUE
#
