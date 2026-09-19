module JournalHelper
  def journal_cell_id(shot, field)
    "#{dom_id(shot, :journal)}_#{field.unpack1('H*')}"
  end

  def journal_input_type(field)
    if field == "start_time"
      "datetime-local"
    elsif %w[duration espresso_enjoyment].include?(field) || Shot::TASTING_ASSESSMENT_ATTRIBUTES.map(&:to_s).include?(field)
      "number"
    else
      "text"
    end
  end

  def journal_display(shot, field)
    if Journal::NOTES.include?(field)
      shot.rich_text_plain_text(field).to_s.truncate(90)
    elsif field == "start_time"
      shot.start_time.in_time_zone(Current.timezone).strftime("%b %-d, %H:%M")
    elsif field == "duration"
      shot.duration&.round(1).to_s
    elsif %w[bean_weight drink_weight drink_tds drink_ey].include?(field)
      value = journal.value(shot, field).to_s
      value.match?(/\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)\z/) && value.to_f.finite? ? value.to_f.truncate(4).to_s : value
    else
      journal.value(shot, field).to_s
    end
  end
end
