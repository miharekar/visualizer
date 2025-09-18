class UserMailer < ApplicationMailer
  def yearly_brew
    @user = params[:user]
    @yearly_brew = YearlyBrew.new(@user, 2024)

    mail to: @user.email, subject: "Bean Counting 2024: Your Year on Visualizer"
  end

  def black_friday
    @user = params[:user]
    mail to: @user.email, subject: "A Different Kind of Black Friday on Visualizer"
  end

  def cancelled_after_trial
    @user = params[:user]
    mail to: @user.email, subject: "Visualizer Premium Feedback"
  end

  def cancelled_premium
    @user = params[:user]
    mail to: @user.email, subject: "Visualizer Premium Feedback"
  end
end
