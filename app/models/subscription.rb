class Subscription < ApplicationRecord
  belongs_to :customer
end

# == Schema Information
#
# Table name: subscriptions
#
#  id                   :uuid             not null, primary key
#  cancel_at            :datetime
#  cancellation_details :jsonb
#  cancelled_at         :datetime
#  ended_at             :datetime
#  interval             :string
#  started_at           :datetime
#  status               :string
#  customer_id          :uuid             not null
#  stripe_id            :string
#
# Indexes
#
#  index_subscriptions_on_customer_id  (customer_id)
#  index_subscriptions_on_stripe_id    (stripe_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#
