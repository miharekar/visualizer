class Subscription < ApplicationRecord
  belongs_to :user, optional: true
end

# == Schema Information
#
# Table name: subscriptions
#
#  id           :uuid             not null, primary key
#  cancel_at    :datetime
#  cancelled_at :datetime
#  ended_at     :datetime
#  interval     :string
#  started_at   :datetime
#  status       :string
#  stripe_id    :string
#  user_id      :uuid
#
# Indexes
#
#  index_subscriptions_on_stripe_id  (stripe_id)
#  index_subscriptions_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
