class ApplicationMailer < ActionMailer::Base
  before_action :check_subscription

  default from: email_address_with_name("miha@visualizer.coffee", "Miha Rekar"), message_stream: -> { notification_exists? ? "broadcast" : "outbound" }
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

    if params[:user].notify?(action_name)
      token = params[:user].unsubscribe_token_for(action_name)
      headers["List-Unsubscribe"] = "<#{emails_unsubscribe_url(token:)}>, <mailto:miha@visualizer.coffee?subject=Unsubscribe>"
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    else
      self.response_body = :do_not_deliver
    end

    self.response_body = :do_not_deliver unless params[:user].notify?(action_name)
  end

  def notification_exists?
    User::EMAIL_NOTIFICATIONS.include?(action_name.to_s)
  end
end
