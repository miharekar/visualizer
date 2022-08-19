# frozen_string_literal: true

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Shots by #{@user.name}"
    xml.description "These are the last 30 shots by #{@user.name}."
    xml.link feed_person_url(@user, format: :rss)
    xml.lastBuildDate @shots.first.start_time.rfc822 unless @user.hide_shot_times?

    @shots.each do |shot|
      xml.item do
        xml.title shot.profile_title
        xml.link shot_url(shot)
        xml.description render(partial: "shot", locals: {shot:})
        xml.guid shot_url(shot.id)
        xml.pubDate shot.start_time.rfc822 unless @user.hide_shot_times?
      end
    end
  end
end
