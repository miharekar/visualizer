# frozen_string_literal: true

class ChangelogsController < ApplicationController
  before_action :check_admin!, except: %i[index]
  before_action :set_changelog, only: %i[edit update destroy]

  def index
    @changelogs = Changelog.order(published_at: :desc)
  end

  def new
    @changelog = Changelog.new
  end

  def edit; end

  def create
    @changelog = Changelog.new(changelog_params)

    if @changelog.save
      redirect_to @changelog, notice: "Changelog was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @changelog.update(changelog_params)
      redirect_to @changelog, notice: "Changelog was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_changelog
    @changelog = Changelog.find(params[:id])
  end

  def changelog_params
    params.require(:changelog).permit(:title, :body, :published_at)
  end
end
