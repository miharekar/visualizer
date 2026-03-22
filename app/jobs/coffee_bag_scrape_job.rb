class CoffeeBagScrapeJob < ApplicationJob
  def perform(user, url, request_id)
    return unless user

    data = CoffeeBagScraper.new(user, url, request_id).scrape
    CoffeeBagScraperChannel.broadcast_to(user, {request_id:, data:})
  rescue StandardError => e
    Appsignal.report_error(e)
    CoffeeBagScraperChannel.broadcast_to(user, {request_id:, error: e.message})
  end
end
