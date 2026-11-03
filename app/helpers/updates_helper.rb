module UpdatesHelper
  LINK_ATTRIBUTES = %w[href src].freeze

  def absolute_update_body(update)
    item_url = update_url(update.slug.presence || update.id)
    fragment = Nokogiri::HTML5.fragment(update.body.to_s)
    fragment.css("[href], [src]").each do |node|
      LINK_ATTRIBUTES.each do |attribute|
        value = node[attribute]
        if value&.start_with?("#")
          node[attribute] = item_url + value
        elsif value&.start_with?("/") && !value.start_with?("//")
          node[attribute] = request.base_url + value
        end
      end
    end
    fragment.to_html
  end
end
