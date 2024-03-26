class AirtableShotDownloadJob < AirtableJob
  def perform(user, minutes: 60)
    Airtable::Shots.new(user).download(minutes:)
  end
end
