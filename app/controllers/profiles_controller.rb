class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_profile
  before_action :set_authorized_applications

  def edit; end

  def update
    if @profile.update(profile_params)
      flash[:notice] = "Profile successfully updated."
      redirect_to controller: "shots", action: :index, format: :html
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@profile, partial: "form") }
        format.html { render :edit }
      end
    end
  end

  def reset_chart_settings
    @profile.update(chart_settings: nil)
    flash[:notice] = "Chart settings were reset to default."
    redirect_to edit_profile_path(@profile)
  end

  def add_metadata_field
    field = params[:field].gsub(/[^\w ]/, "").squish
    if field.present?
      fields = @profile.metadata_fields + [field]
      @profile.update(metadata_fields: fields.uniq)
      redirect_to edit_profile_path(@profile), notice: "#{field} added to custom fields."
    else
      redirect_to edit_profile_path(@profile), alert: "Field name cannot be blank."
    end
  end

  def remove_metadata_field
    if @profile.metadata_fields.include?(params[:field])
      fields = @profile.metadata_fields - [params[:field]]
      @profile.update(metadata_fields: fields.uniq)
      redirect_to edit_profile_path(@profile), notice: "#{params[:field]} removed from custom fields."
    else
      redirect_to edit_profile_path(@profile), alert: "#{params[:field]} not found in custom fields."
    end
  end

  def decent_serial_numbers
    @serial_numbers = DecentApi.new(@profile.decent_email, @profile.decent_token).serial_numbers
  rescue StandardError
    @serial_numbers = []
  end

  def disconnect_airtable
    airtables = @profile.identities.by_provider(:airtable)
    return unless airtables.exists?

    airtables.destroy_all
    redirect_to edit_profile_path(@profile), notice: "Airtable disconnected."
  end

  private

  def set_profile
    @profile = params.key?(:id) && Current.user.admin? ? User.find(params[:id]) : Current.user
  end

  def set_authorized_applications
    @authorized_applications = Doorkeeper.config.application_model.authorized_for(Current.user)
  end

  def profile_params
    allowed_params = %i[avatar name timezone temperature_unit date_format skin public hide_shot_times]
    allowed_params << %i[github supporter developer] if Current.user.admin?
    allowed_params << %i[coffee_management_enabled] if Current.user.premium?
    notification_settings = {unsubscribed_from: (User::EMAIL_NOTIFICATIONS - params[:user][:email_notifications]) || []}

    params.expect(user: allowed_params).merge(chart_settings).merge(notification_settings)
  end

  def chart_settings
    return unless @profile.premium?

    settings = ChartSettings::DEFAULT.keys.index_with do |label|
      {
        "color" => params["user"]["#{label}-color"],
        "type" => params["user"]["#{label}-type"],
        "dashed" => ActiveModel::Type::Boolean.new.cast(params["user"]["#{label}-dashed"]),
        "hidden" => ActiveModel::Type::Boolean.new.cast(params["user"]["#{label}-hidden"])
      }
    end

    {chart_settings: settings}
  end
end
