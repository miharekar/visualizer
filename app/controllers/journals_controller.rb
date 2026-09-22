class JournalsController < ApplicationController
  before_action :require_authentication

  rescue_from Journal::InvalidChange, ActiveRecord::RecordInvalid do |error|
    @error = error.message
    @fields = [@field]
    @shots ||= []
    render(action_name == "update" ? :update : :edit, formats: [action_name == "update" ? :turbo_stream : :html], status: :unprocessable_content)
  end
  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def edit
    @editor = true
    @shots = []
    if params[:ids].present?
      @field = params[:field]
      raise Journal::InvalidChange, "Some fields are not editable" unless journal.editable_columns.key?(@field)

      load_coffee_bags
      @shots = journal.shots(params[:ids], fields: [@field])
      @value = if @field == "tag_list"
        @shots.map { it.tags.map(&:name) }.reduce(:&).sort.join(",")
      elsif @field == "coffee" && @shots.one?
        @shots.first.coffee_bag_id
      elsif @shots.one?
        journal.value(@shots.first, @field)
      end
    end
  end

  def update
    @editor = ActiveModel::Type::Boolean.new.cast(params[:editor])
    @value = params[:value]
    @field = params[:field]
    load_coffee_bags
    raise Journal::InvalidChange, "Some fields are not editable" unless journal.editable_columns.key?(@field)

    @shots = journal.shots(params[:ids], fields: [@field])
    journal.update(@shots, field: @field, value: @value)
    @fields = [@field]
    @fields << "ratio" if %w[bean_weight drink_weight].include?(@field)
    @fields |= Journal::BAG_FIELDS & journal.columns.keys if @field == "coffee"
    render :update, formats: [:turbo_stream]
  end

  private

  def load_coffee_bags
    @coffee_bags = Current.user.coffee_bags.includes(:roaster).by_brewability.by_roast_date.by_name if @field == "coffee"
  end
end
