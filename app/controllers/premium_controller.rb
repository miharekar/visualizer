# frozen_string_literal: true

class PremiumController < ApplicationController
  def index
    return if current_user.beta?

    redirect_to "https://github.com/sponsors/miharekar", allow_other_host: true
  end

  def create
    session = Stripe::Checkout::Session.create(
      {
        success_url: "#{success_premium_index_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_premium_index_url,
        mode: "subscription",
        automatic_tax: {enabled: true},
        line_items: [{
          quantity: 1,
          price: ENV["STRIPE_PRICE"]
        }]
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def update
    session = Stripe::BillingPortal::Session.create(
      {
        customer: current_user.stripe_customer_id,
        return_url: shots_url
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    current_user.update(stripe_customer_id: session.customer, premium: true)
    flash[:notice] = "Subscribing was successful"
    redirect_to shots_path
  end

  def cancel
    flash[:alert] = "Subscribing was cancelled."
    redirect_to shots_path
  end
end
