xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:content" => "http://purl.org/rss/1.0/modules/content/", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Visualizer Updates"
    xml.description "These are the latest updates from Visualizer"
    xml.link updates_url
    xml.lastBuildDate @updates.first.published_at.rfc822 if @updates.present?
    xml.tag! "atom:link", href: feed_updates_url(format: "rss"), rel: "self", type: "application/rss+xml"

    @updates.each do |update|
      xml.item do
        xml.title update.title
        xml.description update.excerpt
        xml.tag! "content:encoded", absolute_update_body(update)
        xml.link update_url(update.slug.presence || update.id)
        xml.guid update_url(update.slug.presence || update.id), isPermaLink: true
        xml.pubDate update.published_at.rfc822
      end
    end
  end
end
