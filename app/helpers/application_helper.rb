# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def custom_pagy_url_for(number, pagy, url)
    if url.blank?
      pagy_url_for(number, pagy)
    else
      join_char = url.include?("?") ? "&" : "?"
      "#{url}#{join_char}page=#{number}"
    end
  end

  def avatar_url(user, size)
    user.avatar.attached? ? url_for(user.avatar) : "#{user.gravatar_url}?s=#{size}&d=mp"
  end
end
