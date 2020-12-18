# frozen_string_literal: true

class PeopleController < ApplicationController
  def index
    @users = User.where(public: true)
  end

  def show
    @user = User.find(params[:id])
    @shots = @user.shots
  end
end
