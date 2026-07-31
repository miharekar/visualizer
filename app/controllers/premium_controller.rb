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
