# frozen_string_literal: true

class PeopleController < ApplicationController
  SEARCH_LIMIT = 15
  include Pagy::Backend

  def index
    @users = User.visible.by_name
    @pagy, @users = pagy_array(@users, items: SEARCH_LIMIT)
  end

  def search
    @users = User.visible.by_name.where("name ILIKE ?", "%#{params[:name]}%")
    @pagy, @users = pagy_array(@users, items: SEARCH_LIMIT, params: {name: params[:name]})
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(:users, partial: "people/users", locals: {users: @users, pagy: @pagy}) }
      format.html { render :index }
    end
  end

  def show
    @user = User.find_by(slug: params[:id])

    if @user.nil?
      @user = User.find_by(id: params[:id])
      return redirect_to people_path, alert: "User #{params[:id]} was not found" if @user.nil?
      return redirect_to person_path(slug: @user.slug), status: :moved_permanently if @user.public?
    end

    if @user.public
      @shots = @user.shots.by_start_time
      @pagy, @shots = pagy_countless(@shots)
    else
      redirect_to :root
    end
  end

  def feed
    @user = User.find_by(slug: params[:id])
    @user = User.find_by(id: params[:id]) if @user.nil?

    if @user&.public
      @shots = @user.shots.by_start_time.limit(30)
    else
      head :not_found
    end
  end
end
