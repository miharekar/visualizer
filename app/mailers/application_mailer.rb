class ApplicationMailer < ActionMailer::Base
  MAIL_FROM = ENV.fetch("SMTP_FROM", ENV["VISUALIZER_SELF_HOSTED"] == "true" ? "auth@private-testumgebung.de" : "miha@visualizer.coffee")

  before_action :check_notification

  default from: email_address_with_name(MAIL_FROM, "Miha from Visualizer"), message_stream: -> { notification_exists? ? "broadcast" : "outbound" }
  layout "mailer"
  helper_method :notification_exists?

  rescue_from(Exception) do
    Appsignal.report_error(it)
    raise it
  end

  private

  def check_notification
    return unless params.try(:[], :user).is_a?(User)
    return self.response_body = :do_not_deliver if params[:user].disabled? || !params[:user].confirmed?
    return unless notification_exists?

    if params[:user].notify?(action_name)
      token = params[:user].unsubscribe_token_for(action_name)
      headers["List-Unsubscribe"] = "<#{emails_unsubscribe_url(token:)}>, <mailto:#{MAIL_FROM}?subject=Unsubscribe>"
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
