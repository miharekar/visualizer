class HomeController < ApplicationController
  def show
    @user_count = (User.count / 100).floor * 100
    @updates = Update.order(published_at: :desc).limit(3).to_a
    @last_update = @updates.shift
  end

  def privacy
  end
end
