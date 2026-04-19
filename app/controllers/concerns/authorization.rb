module Authorization
  extend ActiveSupport::Concern
  include ActionPolicy::Controller

  included do
    authorize :user, through: -> { Current.user }
    rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized
  end

  private

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

  def user_not_authorized(exception)
    message = exception.result.message
    if request.format.json?
      render json: {error: message}, status: :forbidden
    else
      redirect_back_or_to default_path, alert: message
    end
  end
end
