module Authorization
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def pundit_user
    Current.user
  end

  def check_admin!
    redirect_to shots_path unless Current.user.admin?
  end

  def check_premium!
    redirect_to premium_index_path, alert: "You must be a premium user to access this feature." unless Current.user.premium?
  end

  def user_not_authorized
    redirect_back_or_to shots_path, alert: "You are not authorized to perform this action."
  end
end
