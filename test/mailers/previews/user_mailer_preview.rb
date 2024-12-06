class UserMailerPreview < ActionMailer::Preview
  def yearly_brew
    user = User.admin
    UserMailer.with(user:).yearly_brew
  end

  def black_friday
    user = User.order("RANDOM()").first
    UserMailer.with(user:).black_friday
  end
end
