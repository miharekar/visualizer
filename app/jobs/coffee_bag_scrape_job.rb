class CoffeeBagScrapeJob < ApplicationJob
  def perform(user, url, request_id)
    return unless user

    info = CoffeeBagScraper.new.get_info(url)
    payload = {request_id:}
    info[:error].present? ? payload[:error] = info[:error] : payload[:data] = info
    CoffeeBagScraperChannel.broadcast_to(user, payload)
  rescue StandardError => e
    Appsignal.report_error(e)
    CoffeeBagScraperChannel.broadcast_to(user, {request_id:, error: e.message})
  end
end
