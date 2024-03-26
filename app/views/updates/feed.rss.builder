# frozen_string_literal: true

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Visualizer Updates"
    xml.description "These are the latest updates from Visualizer"
    xml.link feed_updates_url
    xml.lastBuildDate @updates.first.published_at.rfc822

    @updates.each do |update|
      xml.item do
        xml.title update.title
        xml.description update.excerpt
        xml.link update_url(update.slug.presence || update.id)
        xml.guid update_url(update.slug.presence || update.id), isPermaLink: true
        xml.pubDate update.published_at.rfc822
      end
    end
  end
end
