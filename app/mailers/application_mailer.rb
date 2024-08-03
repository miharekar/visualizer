class ApplicationMailer < ActionMailer::Base
  before_action :check_subscription

  default from: "Miha Rekar <miha@visualizer.coffee>"
  layout "mailer"
  helper_method :notification_exists?

  rescue_from(Exception) do |exception|
    Appsignal.report_error(exception)
    raise exception
  end

  private

  def check_subscription
    return unless params.try(:[], :user).is_a?(User)
    return unless notification_exists?

    self.response_body = :do_not_deliver unless params[:user].notify?(action_name)
  end

  def notification_exists?
    User::EMAIL_NOTIFICATIONS.include?(action_name.to_s)
  end
end
