class PremiumController < ApplicationController
  before_action :require_authentication, except: [:index]

  def index
    @features = [
      "Create custom fields to track exactly what matters to you",
      "Sync your shots, roasters, and coffee bags with Airtable",
      "Access your complete shot history",
      "Tag your shots to add an extra layer of organization",
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
      ["What payment methods do you accept?", "Credit and debit cards, Apple Pay, Google Pay, and everything else [Lemon Squeezy supports](https://docs.lemonsqueezy.com/help/checkout/payment-methods#supported-payment-methods)."],
      ["Can I use it for free?", "Absolutely! The free plan is here to stay."],
      ["Do you have a free trial?", "Yes! Try premium free for #{helpers.free_trial_days} days. Cancel anytime during the trial and you won't be charged."],
      ["Do you have a refund policy?", "While I don't have a formal policy, just [drop me a line](mailto:miha@visualizer.coffee) if you need help with a refund."],
      ["Do you offer any discounts?", "[No](/updates/black-friday). I keep things simple with one straightforward price! But you can save 2 months worth when you pick the annual plan."],
      ["Do you have a privacy policy?", "Sure do! Read it [here](/privacy)."],
      ["Can I pay with Bitcoin/Ethereum/Dogecoin/…?", "No."],
      ["Can I use it on multiple devices?", "Yes! Use it anywhere you want - no extra charge."],
      ["How did you decide on the price?", "That's quite a story! Read all about it in [this post](/updates/visualizer-v3)."],
      ["What's your favorite exercise?", "The daily grind."]
    ].shuffle + [
      ["What if I have more questions?", "Just [send me a message](mailto:miha@visualizer.coffee) - I'm here to help!"]
    ]
  end

  def create
    if Current.user.premium_expires_at&.future?
      redirect_to shots_path, flash: {premium: "You're already a premium user. Thank you for your support! 🙏"}
    elsif Current.user.beta?
      data = {
        product_id: Rails.application.credentials.creem.product_id,
        success_url: success_premium_index_url(host: "localhost:3000"),
        customer: {email: Current.user.email},
        metadata: {user_id: Current.user.id}
      }

      checkout = Creem.new.create_checkout(data)
      redirect_to checkout["checkout_url"], allow_other_host: true
    else
      data = {
        data: {
          type: "checkouts",
          attributes: {
            checkout_data: {
              email: Current.user.email,
              custom: {user_id: Current.user.id}
            },
            product_options: {
              redirect_url: success_premium_index_url
            },
            checkout_options: {
              skip_trial: Current.user.premium_expires_at.present?
            }
          },
          relationships: {
            variant: {
              data: {
                type: "variants",
                id: Rails.application.credentials.lemon_squeezy.yearly_price_id.to_s
              }
            },
            store: {
              data: {
                type: "stores",
                id: Rails.application.credentials.lemon_squeezy.store_id.to_s
              }
            }
          }
        }
      }

      checkout = LemonSqueezy.new.create_checkout(data)
      redirect_to checkout.dig("data", "attributes", "url"), allow_other_host: true
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
