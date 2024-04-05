class Customer < ApplicationRecord
  belongs_to :user, optional: true
  has_many :subscriptions

  def top_spender?
    amount >= 15000
  end
end

# == Schema Information
#
# Table name: customers
#
#  id        :uuid             not null, primary key
#  address   :jsonb
#  amount    :integer
#  email     :string
#  name      :string
#  payments  :jsonb
#  refunds   :jsonb
#  stripe_id :string
#  user_id   :uuid
#
# Indexes
#
#  index_customers_on_stripe_id  (stripe_id)
#  index_customers_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
