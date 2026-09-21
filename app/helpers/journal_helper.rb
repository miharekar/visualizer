module JournalHelper
  def journal_cell_id(shot, field)
    "#{dom_id(shot, :journal)}_#{field.unpack1('H*')}"
  end

  def journal_input_options(field)
    if field == "duration"
      {type: "number", min: 0, step: "any"}
    elsif field == "espresso_enjoyment"
      {type: "number", min: 0, max: 100, step: 1}
    elsif Shot::TASTING_ASSESSMENT_ATTRIBUTES.map(&:to_s).include?(field)
      {type: "number", min: 0, max: 15, step: 1}
    else
      {type: "text"}
    end
  end

  def journal_display(shot, field)
    if Journal::NOTES.include?(field)
      shot[field].to_s.truncate(90)
    elsif field == "start_time"
      shot.start_time.in_time_zone(Current.timezone).strftime("%b %-d, %H:%M")
    elsif field == "duration"
      shot.duration&.round(1).to_s
    else
      journal.value(shot, field).to_s
    end
  end
end
