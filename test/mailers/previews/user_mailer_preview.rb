# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def yearly_brew
    user = User.order("RANDOM()").first
    UserMailer.with(user:).yearly_brew
  end
end
