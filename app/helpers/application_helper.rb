# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def markdown_text_from(input)
    tags = Rails::Html::SafeListSanitizer.allowed_tags + %w[table thead tbody th tr td video]
    attributes = Rails::Html::SafeListSanitizer.allowed_attributes + %w[id style controls]
    text = sanitize(Kramdown::Document.new(input, input: "GFM").to_html, tags: tags, attributes: attributes)
    tag.div(text, class: "prose dark:prose-dark")
  end

  def custom_pagy_url_for(pagy, number, url)
    if url.blank?
      pagy_url_for(pagy, number)
    else
      join_char = url.include?("?") ? "&" : "?"
      "#{url}#{join_char}page=#{number}"
    end
  end

  def avatar_url(user, size)
    user.avatar.attached? ? url_for(user.avatar) : "#{user.gravatar_url}?s=#{size}&d=mp"
  end

  def change_count
    @change_count ||= Change.where("published_at > ?", current_user.last_read_change).count
  end
end
