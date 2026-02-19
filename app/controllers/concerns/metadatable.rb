module Metadatable
  private

  def create_metadata_field(type)
    field = params[:field].gsub(/[^\w ]/, "").squish
    if field.present?
      attribute = "#{type}_metadata_fields"
      existing_fields = Current.user.public_send(attribute)
      Current.user.update(attribute => (existing_fields + [field]).uniq)
      redirect_to edit_profile_path, notice: "#{field} added to #{type.to_s.humanize} custom fields."
    else
      redirect_to edit_profile_path, alert: "Field name cannot be blank."
    end
  end

  def destroy_metadata_field(type)
    field = params[:field]
    attribute = "#{type}_metadata_fields"
    existing_fields = Current.user.public_send(attribute)
    if existing_fields.include?(field)
      Current.user.update(attribute => (existing_fields - [field]).uniq)
      redirect_to edit_profile_path, notice: "#{field} removed from #{type.to_s.humanize} custom fields."
    else
      redirect_to edit_profile_path, alert: "#{field} not found in #{type.to_s.humanize} custom fields."
    end
  end
end
