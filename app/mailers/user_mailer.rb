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
end
