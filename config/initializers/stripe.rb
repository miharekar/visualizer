Stripe.api_key = Rails.application.credentials.stripe&.secret_key if Rails.application.credentials.stripe
Stripe.api_version = "2025-07-30.basil; managed_payments_preview=v1"
