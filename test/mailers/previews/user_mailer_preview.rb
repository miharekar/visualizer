class UserMailerPreview < ActionMailer::Preview
  def yearly_brew
    user = User.admin
    UserMailer.with(user:).yearly_brew
  end

  def shot_uploaded
    user = User.admin
    shot = user.shots.order("RANDOM()").first
    UserMailer.with(user:, shot:).shot_uploaded
  end

  %i[black_friday cancelled_premium upcoming_renewal].each do |email|
    define_method(email) do
      user = User.order("RANDOM()").first
      UserMailer.with(user:).public_send(email)
    end
  end
end
