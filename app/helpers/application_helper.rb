module ApplicationHelper
  def avatar_url(user, size)
    if user.avatar.attached? && user.avatar.variable?
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
