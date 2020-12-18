# frozen_string_literal: true

module ApplicationHelper
  def current_path(params = {})
    url_for(request.params.merge(params))
  end
end
