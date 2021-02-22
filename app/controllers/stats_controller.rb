# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to :shots unless current_user.admin?

    @shot_counts = Shot.order("created_at::date").group("created_at::date").count
    @shot_counts = {
      labels: @shot_counts.keys,
      datasets: [{
        backgroundColor: "rgb(209, 250, 229)",
        borderColor: "rgb(4, 120, 87)",
        fill: false,
        label: "Uploaded .shots",
        data: @shot_counts.values
      }]
    }
  end
end
