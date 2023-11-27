# frozen_string_literal: true

module ApplicationHelper
  def markdown_text_from(input)
    tags = Rails::Html::SafeListSanitizer.allowed_tags + %w[table thead tbody th tr td video]
    attributes = Rails::Html::SafeListSanitizer.allowed_attributes + %w[id style controls]
    text = sanitize(Kramdown::Document.new(input, input: "GFM").to_html, tags:, attributes:)
    tag.div(text, class: "prose prose-neutral dark:prose-invert")
  end

  def faq_markdown_text_from(input, link_class: "")
    text = Kramdown::Document.new(input, input: "GFM").to_html
    text = text.gsub(/a href="([^"]+)"/, %(a class="#{link_class}" href="\\1" target="_blank"))
    text.html_safe
  end

  def avatar_url(user, size)
    user.avatar.attached? ? url_for(user.avatar) : "#{user.gravatar_url}?s=#{size}&d=mp"
  end

  def update_count
    @update_count ||= Update.where("published_at > ?", current_user.last_read_change).count
  end

  def show_premium_banner?
    current_user && !current_user.premium? && current_user.shots.premium.any?
  end

  def public_image_url(image)
    if image.respond_to?(:variation)
      blob = image.image&.blob
      if blob.blank?
        ProcessImageJob.perform_later(image.blob, image.variation.transformations)
        blob = image.blob
      end
    else
      blob = image.blob
    end

    blob.url(expires_in: 1.week, disposition: :inline)
  end
end
