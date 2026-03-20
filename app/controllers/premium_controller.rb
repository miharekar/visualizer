class PremiumController < ApplicationController
  before_action :require_authentication, except: [:index]

  def index
    @features = [
      "Access your complete shot history",
      "Find past shots quickly with Instant Filters",
      "Track coffee bags and update related shots in one go",
      "Add tags for another layer of organization",
      "Keep private notes for your future self",
      "Create custom fields to track what matters to you",
      "Sync your shots, roasters, and coffee bags with Airtable",
      "Fetch coffee bag details with AI from a link",
      "Fine-tune shot comparisons with precise timing control",
      "Customize chart colors",
      "Add photos to your shots",
      "Upload over 50 shots per day",
      "Support Visualizer's development and keep the coffee flowing"
    ]

    @qas = [
      ["What's the biggest difference between free and premium?", "Premium unlocks your complete shot history, plus extra tools for organizing and learning from your coffee data."],
      ["Can I use Visualizer for free?", "Absolutely. The free tier is here to stay and already covers the core workflow."],
      ["How much does it cost?", "€5 per month or €50 per year."],
      ["Do you have a free trial?", "Yes. Try Premium free for #{helpers.free_trial_days} days. Cancel anytime during the trial and you won't be charged."],
      ["Do you ever erase shot history for non-premium users?", "Never. Your shots stay safe - they're just hidden until you upgrade."],
      ["If I upgrade later, will I be able to see all my past shots?", "Yep. Every shot you've ever uploaded will be right there waiting for you."],
      ["Can I cancel at any time?", "Of course. You'll keep Premium features until your subscription ends."],
      ["What payment methods do you accept?", "Credit and debit cards, Apple Pay, Google Pay, and everything else [Creem supports](https://docs.creem.io/merchant-of-record/finance/payment-methods)."],
      ["Do you have a refund policy?", "I don't have a formal refund policy, but if you need help, just [send me a message](mailto:miha@visualizer.coffee)."],
      ["Do you offer any discounts?", "[No](/updates/black-friday). I keep things simple with one straightforward price, though the annual plan saves you 2 months."],
      ["Do you have a privacy policy?", "Sure do. Read it [here](/privacy)."],
      ["Can I pay with Bitcoin/Ethereum/Dogecoin/…?", "No."],
      ["Can I use it on multiple devices?", "Yes. Use it anywhere you want at no extra charge."],
      ["How did you decide on the price?", "That's quite a story! Read all about it in [this post](/updates/visualizer-v3)."],
      ["What's your favorite exercise?", "The daily grind."],
      ["What if I have more questions?", "Just [send me a message](mailto:miha@visualizer.coffee) - I'm here to help!"]
    ]
  end

  def create
    if Current.user.premium_expires_at&.future?
      redirect_to manage_premium_index_path
    else
      product_id = Current.user.premium_expires_at.present? ? Rails.application.credentials.creem.product_id : Rails.application.credentials.creem.product_id_trial
      data = {
        product_id:,
        success_url: success_premium_index_url,
        customer: {email: Current.user.email},
        metadata: {user_id: Current.user.id}
      }

      checkout = Creem.new.create_checkout(data)
      redirect_to checkout["checkout_url"], allow_other_host: true
    end
  end

  def manage
    if !Current.user.can_manage_premium?
      redirect_to shots_path, flash: {alert: "You don't have a Premium subscription. Please subscribe first."}
    elsif Current.user.creem_customer_id.present?
      portal = Creem.new.create_customer_portal(Current.user.creem_customer_id)
      redirect_to portal["customer_portal_link"], allow_other_host: true
    else
      customer = LemonSqueezy.new.get_customer(Current.user.lemon_squeezy_customer_id)
      redirect_to customer.dig("data", "attributes", "urls", "customer_portal"), allow_other_host: true
    end
  end

  def success
    flash[:notice] = "Subscribing was successful. Thank you for your support! 🙏"
    redirect_to shots_path
  end
end
