class EmailsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def unsubscribe
    notification = User.unsubscribe_by_token!(params[:token])
    flash[:notice] = "You have been unsubscribed from #{notification.humanize}. You can always resubscribe in your profile." if notification
    redirect_to root_path
  end
end
