module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
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
    return if Current.user.premium?

    message = "You must be a premium user to access this feature."
    if request.format.json?
      render json: {error: message}, status: :forbidden
    else
      redirect_to premium_index_path, alert: message
    end
  end

  def user_not_authorized
    message = "You are not authorized to perform this action."
    if request.format.json?
      render json: {error: message}, status: :forbidden
    else
      redirect_back_or_to default_path, alert: message
    end
  end
end
