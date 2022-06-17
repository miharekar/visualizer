# frozen_string_literal: true

module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_action :authenticate_user! # use before_action instead if on Rails 5.1+

    def index
      @applications = current_user.oauth_applications
    end

    def create
      @application = Doorkeeper::Application.new(application_params)
      @application.owner = current_user
      if @application.save
        flash[:notice] = I18n.t("doorkeeper.flash.applications.create.notice")
        redirect_to oauth_application_url(@application)
      else
        render :new
      end
    end

    private

    def set_application
      @application = current_user.oauth_applications.find(params[:id])
    end
  end
end
