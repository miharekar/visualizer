class UserMailer < ApplicationMailer
  def yearly_brew
    @user = params[:user]
    @yearly_brew = YearlyBrew.new(@user, 2024)

    mail to: @user.email, subject: "Bean Counting 2024: Your Year on Visualizer"
  end

  def shot_uploaded
    @user = params[:user]
    @shot = params[:shot]

    mail to: @user.email, subject: "See your new #{@shot.profile_title} shot 👀"
  end

  def black_friday
    @user = params[:user]
    mail to: @user.email, subject: "A Different Kind of Black Friday on Visualizer"
  end

  def cancelled_premium
    @user = params[:user]
    mail to: @user.email, subject: "Visualizer Premium Feedback"
  end

  def upcoming_renewal
    @user = params[:user]
    mail to: @user.email, subject: "Quick heads-up before your renewal"
  end
end
