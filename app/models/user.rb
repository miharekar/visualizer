# frozen_string_literal: true

class User < ApplicationRecord
  include Sluggable
  slug_from :name

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :shots, dependent: :nullify
  has_many :shared_shots, dependent: :nullify

  has_one_attached :avatar, service: :cloudinary

  scope :visible, -> { where(public: true) }
  scope :by_name, -> { order("LOWER(name)") }

  validates :name, presence: true, if: :public?

  def gravatar_url
    hash = Digest::MD5.hexdigest(email.to_s.downcase)
    "https://www.gravatar.com/avatar/#{hash}.jpg"
  end

  def chart_settings
    return ShotChart::CHART_SETTINGS unless premium?

    super.presence || ShotChart::CHART_SETTINGS
  end

  def premium?
    premium_expires_at&.future? || supporter
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
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  github                 :string
#  hide_shot_times        :boolean
#  last_read_change       :datetime
#  name                   :string
#  premium_expires_at     :datetime
#  public                 :boolean          default(FALSE)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  skin                   :string
#  slug                   :string
#  supporter              :boolean
#  timezone               :string
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
