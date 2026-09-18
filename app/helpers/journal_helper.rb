module JournalHelper
  def journal_input_type(field)
    if field == "start_time"
      "datetime-local"
    elsif %w[duration espresso_enjoyment].include?(field) || Shot::TASTING_ASSESSMENT_ATTRIBUTES.map(&:to_s).include?(field)
      "number"
    else
      "text"
    end
  end

  def journal_display(journal, shot, field)
    if Journal::NOTES.include?(field)
      shot.rich_text_plain_text(field).to_s.truncate(90)
    elsif field == "start_time"
      shot.start_time.in_time_zone(Current.timezone).strftime("%b %-d, %H:%M")
    else
      journal.value(shot, field).to_s
    end
  end
end
