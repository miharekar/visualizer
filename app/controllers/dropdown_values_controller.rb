class DropdownValuesController < ApplicationController
  before_action :require_authentication

  def index
    @kind = params[:kind].presence_in(DropdownValue::VALID_KINDS) || DropdownValue::VALID_KINDS.first
    @dropdown_values = DropdownValue.for(Current.user, @kind).order(Arel.sql("hidden_at IS NOT NULL"), :value)
    @dropdown_kinds = {"grinder_model" => "Grinder"}
    @dropdown_kinds = @dropdown_kinds.merge("bean_brand" => "Roaster", "bean_type" => "Coffee") unless Current.user.coffee_management_enabled?
  end

  def update
    dropdown_value = Current.user.dropdown_values.find(params[:id])
    dropdown_value.toggle!
    render turbo_stream: turbo_stream.replace(dropdown_value)
  end
end
