module ApplicationHelper
  def notes_text_from(input)
    html = input.respond_to?(:body) ? input.body&.to_html : Markdown.to_html(input)
    tag.div(html.to_s.html_safe, class: "lexxy-content prose prose-neutral dark:prose-invert", data: {controller: "syntax-highlight"}) # rubocop:disable Rails/OutputSafety
  end

  def note_editor(form, attribute, content:)
    html = content.respond_to?(:body) ? content.body&.to_html : Markdown.to_html(content)
    form.lexxy_rich_text_area(attribute, value: html)
  end

  def faq_markdown_text_from(input, link_class: "")
    fragment = Nokogiri::HTML5.fragment(Markdown.to_html(input))
    fragment.css("a").each do |link|
      link["class"] = link_class
      link["target"] = "_blank"
      link["rel"] = "noopener noreferrer"
    end
    fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def avatar_url(user, size)
    if user.avatar.attached?
      rails_representation_url(user.avatar.variant(:thumb))
    else
      "#{user.gravatar_url}?s=#{size}&d=mp"
    end
  end

  def update_count
    @update_count ||= Update.where("published_at > ?", Current.user.last_read_change || Time.current).count
  end

  def show_premium_banner?
    Current.user && !Current.user.premium? && Current.user.shots.premium.any?
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

  def free_trial_days
    7
  end

  def local_datetime_tag(datetime, style: :datetime, **attributes)
    tag.time(datetime.to_date.to_fs(:long), datetime: datetime.iso8601, data: {local_time_target: style})
  end
end
