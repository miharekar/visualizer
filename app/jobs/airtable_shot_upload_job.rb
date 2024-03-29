class AirtableShotUploadJob < AirtableJob
  def perform(shot)
    Airtable::Shots.new(shot.user).upload(shot)
  rescue Airtable::DataError => e
    Appsignal.set_error(e) do |transaction|
      transaction.set_tags(shot_id: shot.id, user_id: shot.user_id)
    end
  end
end
