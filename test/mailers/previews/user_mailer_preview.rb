class UserMailerPreview < ActionMailer::Preview
  def yearly_brew
    user = User.admin
    UserMailer.with(user:).yearly_brew
  end

  %i[black_friday cancelled_after_trial cancelled_premium].each do |method|
    define_method(method) do
      user = User.order("RANDOM()").first
      UserMailer.with(user:).public_send(method)
    end
  end
end
