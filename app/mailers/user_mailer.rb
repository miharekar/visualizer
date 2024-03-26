class UserMailer < ApplicationMailer
  def yearly_brew
    @user = params[:user]
    @yearly_brew = YearlyBrew.new(@user)

    mail to: @user.email, subject: "Bean There, Brewed That: Your Year in Coffee"
  end
end
