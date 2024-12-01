class YearlyBrewController < ApplicationController
  WHITELISTED_YEARS = [2023, 2024].freeze

  attr_reader :year

  before_action :require_authentication, except: [:show]
  before_action :set_year, only: %i[index show]

  def index
    @yearly_brew = YearlyBrew.new(Current.user, year)
    render template: "yearly_brew/index_#{year}"
  end

  def show
    @user = User.visible.find_by(slug: params[:slug])

    if @user
      @yearly_brew = YearlyBrew.new(@user, year)
      render template: "yearly_brew/show_#{year}"
    else
      flash[:alert] = "Yearly Brew not found"
      if Current.user
        redirect_to action: :index
      else
        redirect_to root_path
      end
    end
  end

  private

  def set_year
    @year = (params[:year].presence || 2023).to_i
    @year = 2023 unless WHITELISTED_YEARS.include?(@year)
  end
end
