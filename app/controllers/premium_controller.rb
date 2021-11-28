# frozen_string_literal: true

class PremiumController < ApplicationController
  def index; end

  def create
    session = Stripe::Checkout::Session.create(
      {
        success_url: "#{success_premium_index_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_premium_index_url,
        mode: "subscription",
        automatic_tax: {enabled: true},
        line_items: [{
          quantity: 1,
          price: "price_1K0kEjDIrE9MNkF4rDo4PtkM"
        }]
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def update
    checkout_session = Stripe::Checkout::Session.retrieve(current_user.stripe_session_id)
    session = Stripe::BillingPortal::Session.create(
      {
        customer: checkout_session.customer,
        return_url: shots_url
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def success
    flash[:notice] = "Subscribing was successful"
    current_user.update(stripe_session_id: params["session_id"], premium: true)
    redirect_to shots_path
  end

  def cancel
    flash[:alert] = "Subscribing was cancelled."
    redirect_to shots_path
  end
end
