module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_action :require_authentication

    def index
      @applications = Current.user.oauth_applications
    end

    def create
      @application = Doorkeeper::Application.new(application_params)
      @application.owner = Current.user
      if @application.save
        flash[:notice] = I18n.t("doorkeeper.flash.applications.create.notice")
        redirect_to oauth_application_url(@application)
      else
        render :new
      end
    end

    private

    def set_application
      @application = Current.user.oauth_applications.find(params[:id])
    end
  end
end
