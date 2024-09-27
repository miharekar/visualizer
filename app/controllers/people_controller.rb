class PeopleController < ApplicationController
  include CursorPaginatable

  def show
    @user = User.find_by(slug: params[:id])
    if @user.nil?
      @user = User.find_by(id: params[:id])
      if @user&.slug.present?
        redirect_to person_path(id: @user.slug), status: :moved_permanently
      else
        redirect_to community_index_path, alert: "User #{params[:id]} was not found"
      end
    elsif !@user.public
      redirect_to community_index_path, alert: "User #{params[:id]} was not found"
    else
      @shots = @user.shots
      unless Current.user&.premium?
        @premium_count = @shots.premium.count
        @shots = @shots.non_premium
      end
      @shots, @cursor = paginate_with_cursor(@shots.for_list, by: :start_time, before: params[:before])
    end
  end

  def feed
    @user = User.find_by(slug: params[:id])
    if @user.nil?
      @user = User.find_by(id: params[:id])
      if @user&.slug.present?
        redirect_to feed_person_path(id: @user.slug), status: :moved_permanently
      else
        head :not_found
      end
    elsif !@user.public
      head :not_found
    else
      @shots = @user.shots.by_start_time.non_premium.limit(30)
      render formats: :rss
    end
  end
end
