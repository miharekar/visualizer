# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    redirect_to :shots if user_signed_in?

    @shot_count = Shot.count
    @user_count = User.count
    @shot_counts = Shot.where(created_at: (1.month.ago..)).group("created_at::date").count
    @shot_counts = {
      labels: @shot_counts.keys,
      datasets: [{
        backgroundColor: "rgb(209, 250, 229)",
        borderColor: "rgb(4, 120, 87)",
        fill: false,
        pointRadius: 0,
        label: "Uploaded .shots by day",
        data: @shot_counts.values
      }]
    }
  end

  def privacy; end
end
