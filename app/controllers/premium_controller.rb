# frozen_string_literal: true

class PremiumController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @features = [
      "View all shots you ever uploaded",
      "Search across all public shots ever uploaded",
      "Easily check grinder settings of recent coffee/profile combinations",
      "Have a beautiful chart of your espresso enjoyment over time",
      "Customize charts",
      "Adjust the timing of comparison shot",
      "Attach images to your shots",
      "Add private notes to your shots",
      "Get a checkmark next to your name"
    ].shuffle + ["Support development of new features"]
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
    price_id = Stripe::Price.list(active: true, recurring: {interval: "month"}).first.id
    session = Stripe::Checkout::Session.create(
      success_url: "#{success_premium_index_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_premium_index_url,
      mode: "subscription",
      allow_promotion_codes: true,
      customer_email: current_user.email,
      automatic_tax: {enabled: true},
      metadata: {user_id: current_user.id},
      line_items: [{quantity: 1, price: price_id}],
      tax_id_collection: {enabled: true},
      subscription_data: {trial_period_days: 7}
    )
    redirect_to session.url, allow_other_host: true
  end

  def update
    session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: shots_url
    )
    redirect_to session.url, allow_other_host: true
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Stripe::Subscription.retrieve(session.subscription)
    current_user.update(
      stripe_customer_id: session.customer,
      premium_expires_at: Time.zone.at(subscription.current_period_end)
    )
    flash[:notice] = "Subscribing was successful"
    redirect_to shots_path
  end

  def cancel
    flash[:alert] = "Subscribing was cancelled."
    redirect_to shots_path
  end
end
