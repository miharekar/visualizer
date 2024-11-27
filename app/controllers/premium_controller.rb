class PremiumController < ApplicationController
  before_action :require_authentication, except: [:index]

  def index
    @features = [
      "Create custom fields to track exactly what matters to you",
      "Sync your shots, roasters, and coffee bags with Airtable",
      "Access your complete shot history",
      "Browse through the community's public shot collection",
      "Upload over 50 shots per day",
      "Make charts your own with custom colors",
      "Dig deep in your shot comparisons with precise timing control",
      "Add photos to document your coffee journey",
      "Keep private notes for your future self",
      "Show off your Premium status with a shiny checkmark",
      "Find past shots in a flash with Instant Filters",
      "Track your coffee bags and update related shots in one go",
      "Fetch coffee bag details with AI by just pasting a link with information"
    ].shuffle + ["Support Visualizer's development and keep the coffee flowing"]

    @qas = [
      ["What's the biggest difference between free and premium?", "Premium lets you see your complete shot history. Free users can only see their shots from the last month."]
    ] + [
      ["How much does it cost?", "€5 per month or €50 per year."],
      ["Do you ever erase shot history for non-premium users?", "Never! Your shots stay safe - they're just hidden until you upgrade."],
      ["If I decide to upgrade, will I be able to see all my past shots?", "Yep! Every single shot you've ever uploaded will be right there waiting for you."],
      ["Can I cancel at any time?", "Of course! You'll keep premium features until your subscription ends."],
      ["What payment methods do you accept?", "Credit and debit cards through [Stripe](https://stripe.com/)."],
      ["Can I use it for free?", "Absolutely! The free plan is here to stay."],
      ["Do you have a free trial?", "Yes! Try premium free for 37 days. Cancel anytime during the trial and you won't be charged."],
      ["Do you have a refund policy?", "While I don't have a formal policy, just [drop me a line](mailto:miha@visualizer.coffee) if you need help with a refund."],
      ["Do you offer any discounts?", "[No](/updates/black-friday). I keep things simple with one straightforward price! But you can save 2 months worth when you pick the annual plan."],
      ["Do you have a privacy policy?", "Sure do! Read it [here](/privacy)."],
      ["Can I pay with Bitcoin/Ethereum/Dogecoin/…?", "No."],
      ["Can I use it on multiple devices?", "Yes! Use it anywhere you want - no extra charge."],
      ["How did you decide on the price?", "That's quite a story! Read all about it in [this post](/updates/visualizer-v3)."],
      ["What's that about contributing 1% of the subscription to removing CO₂ from the atmosphere?", "I love what Stripe is doing with their [Climate program](https://stripe.com/climate), so I'm pitching in to help."],
      ["What's your favorite exercise?", "The daily grind."]
    ].shuffle + [
      ["What if I have more questions?", "Just [send me a message](mailto:miha@visualizer.coffee) - I'm here to help!"]
    ]
  end

  def create
    if Current.user.premium_expires_at&.future?
      redirect_to shots_path, flash: {premium: "You're already a premium user. Thank you for your support!"}
    else
      price_id = Stripe::Price.list(active: true, recurring: {interval: "month"}).first.id
      session_params = {
        success_url: "#{success_premium_index_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_premium_index_url,
        mode: "subscription",
        allow_promotion_codes: true,
        automatic_tax: {enabled: true},
        metadata: {user_id: Current.user.id},
        line_items: [{quantity: 1, price: price_id}]
      }

      if Current.user.stripe_customer_id.present?
        session_params[:customer] = Current.user.stripe_customer_id
      else
        session_params = session_params.merge(
          customer_email: Current.user.email,
          tax_id_collection: {enabled: true},
          subscription_data: {trial_period_days: 37}
        )
      end

      session = Stripe::Checkout::Session.create(session_params)
      redirect_to session.url, allow_other_host: true
    end
  end

  def manage
    if Current.user.stripe_customer_id.blank?
      redirect_to shots_path, flash: {alert: "You don't have a Stripe customer ID. Please subscribe first."}
    else
      session = Stripe::BillingPortal::Session.create(
        customer: Current.user.stripe_customer_id,
        return_url: shots_url
      )
      redirect_to session.url, allow_other_host: true
    end
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Stripe::Subscription.retrieve(session.subscription)
    Current.user.update(
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
