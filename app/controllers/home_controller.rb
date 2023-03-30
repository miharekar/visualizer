# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    @user_count = (User.count / 100).floor * 100
    @changes = Change.order(published_at: :desc).limit(3).to_a
    @last_change = @changes.shift
  end

  def privacy
  end
end
