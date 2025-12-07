class YearlyBrewController < ApplicationController
  WHITELISTED_YEARS = [2023, 2024, 2025].freeze

  attr_reader :year

  before_action :require_authentication, except: [:show]
  before_action :set_year

  def personal
    @yearly_brew = YearlyBrew.new(Current.user, year)
    render template: "yearly_brew/personal_#{year}"
  end

  def show
    @user = User.visible.find_by(slug: params[:slug])

    if @user && WHITELISTED_YEARS.include?(year)
      @yearly_brew = YearlyBrew.new(@user, year)
      render template: "yearly_brew/show_#{year}"
    else
      flash[:alert] = "Yearly Brew not found"
      if Current.user
        redirect_to action: :personal, year: 2025
      else
        redirect_to root_path
      end
    end
  end

  private

  def set_year
    @year = params[:year].presence.to_i
  end
end
