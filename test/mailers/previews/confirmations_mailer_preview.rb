class ConfirmationsMailerPreview < ActionMailer::Preview
  def confirm
    ConfirmationsMailer.confirm(User.take)
  end
end
