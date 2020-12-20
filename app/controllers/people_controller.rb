# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    @users = User.where(public: true).order(:name)
  end

  def show
    @user = User.find(params[:id])

    if @user.public
      @shots = @user.shots.order(start_time: :desc)
      @pagy, @shots = pagy(@shots)
      render json: {next: @pagy.next, html: render_to_string(partial: "shots/pagy", locals: {shots: @shots})} if params[:page]
    else
      redirect_to :root
    end
  end
end
