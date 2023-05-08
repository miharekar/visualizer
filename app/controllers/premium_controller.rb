# frozen_string_literal: true

class PremiumController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @features = [
      "Create custom fields for tailored shot data",
      "Effortlessly sync with Airtable",
      "Access your complete shot history",
      "Explore the vast archive of public shots",
      "Quickly review grinder settings of recent coffee/profile combinations",
      "Visualize your espresso journey over time with an enjoyment chart",
      "Personalize chart colors",
      "Fine-tune the timing of comparison shot",
      "Attach images to shots for visual documentation and analysis",
      "Keep private notes on shots for future reference",
      "Show off your Premium status with a checkmark next to your name"
    ].shuffle + ["Directly support the development of exciting new features"]
    @qas = [
      ["What's the biggest difference between free and premium?", "With premium, you can see all the shots you ever uploaded. On the free plan, you only see and search amongst the ones that were made in the last month."]
    ] + [
      ["How much does it cost?", "It costs €5 per month or €50 per year."],
      ["Do you ever erase shot history for non-premium users?", "No, never. You simply lose visibility of the old shots, they're still there."],
      ["If I decide to upgrade, will I be able to see all my past shots?", "Yes, absolutely. You'll be able to see all your shots, even the ones you uploaded before subscribing."],
      ["Can I cancel at any time?", "Yes, you can cancel at any time. You will lose access to premium features when your subscription expires."],
      ["What payment methods do you accept?", "I accept credit/debit cards via [Stripe](https://stripe.com/)."],
      ["Can I use it for free?", "Yes, you can absolutely use it for free. The free plan is never going away."],
      ["Do you have a free trial?", "Yes, you can try it for free for 7 days. If you decide to cancel at any time in those 7 days, you won't be charged anything."],
      ["Do you have a refund policy?", "I don't have a specific refund policy. If you want a refund, please [contact me](mailto:miha@visualizer.coffee), and I'll be happy to help you out."],
      ["Do you offer any discounts?", "I [offered discounts before](/changes/world-of-coffee) and might do it again in the future. No plans though. And you do get 2 months worth of discount when you pick the annual plan."],
      ["Do you have a privacy policy?", "Yes, I have a privacy policy. You can read it [here](/privacy)."],
      ["Can I pay with Bitcoin/Ethereum/Dogecoin/…?", "No."],
      ["Can I use it on multiple devices?", "Yes, you can use it on all your devices. You don't need to pay separately for each device."],
      ["How did you decide on the price?", "It's a long story. Feel free to read the [post detailing the reasons](https://visualizer.coffee/changes/visualizer-v3)."],
      ["What's that about contributing 1% of the subscription to removing CO₂ from the atmosphere?", "I'm a big fan of what Stripe is doing, so I wanted to contribute to their [Climate program](https://stripe.com/climate)."],
      ["How do you make holy water?", "You boil the hell out of it."]
    ].shuffle + [
      ["What if I have more questions?", "Please [contact me](mailto:miha@visualizer.coffee), and I'll be happy to help you out."]
    ]
  end

  def create
    if current_user.premium_expires_at&.future?
      redirect_to shots_path, flash: {premium: "You're already a premium user. Thank you for your support!"}
    else
      price_id = Stripe::Price.list(active: true, recurring: {interval: "month"}).first.id
      session_params = {
        success_url: "#{success_premium_index_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_premium_index_url,
        mode: "subscription",
        allow_promotion_codes: true,
        automatic_tax: {enabled: true},
        metadata: {user_id: current_user.id},
        line_items: [{quantity: 1, price: price_id}]
      }

      if current_user.stripe_customer_id.present?
        session_params[:customer] = current_user.stripe_customer_id
      else
        session_params = session_params.merge(
          customer_email: current_user.email,
          tax_id_collection: {enabled: true},
          subscription_data: {trial_period_days: 7}
        )
      end

      session = Stripe::Checkout::Session.create(session_params)
      redirect_to session.url, allow_other_host: true
    end
  end

  def manage
    if current_user.stripe_customer_id.blank?
      redirect_to shots_path, flash: {alert: "You don't have a Stripe customer ID. Please subscribe first."}
    else
      session = Stripe::BillingPortal::Session.create(
        customer: current_user.stripe_customer_id,
        return_url: shots_url
      )
      redirect_to session.url, allow_other_host: true
    end
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Stripe::Subscription.retrieve(session.subscription)
    current_user.update(
      stripe_customer_id: session.customer,
      premium_expires_at: Time.zone.at(subscription.current_period_end) + 1.day
    )
    flash[:notice] = "Subscribing was successful"
    redirect_to shots_path
  end

  def cancel
    flash[:alert] = "Subscribing was cancelled."
    redirect_to shots_path
  end
end
