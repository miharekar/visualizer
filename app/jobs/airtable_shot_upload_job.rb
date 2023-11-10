# frozen_string_literal: true

class AirtableShotUploadJob < AirtableJob
  def perform(shot)
    Airtable::Shots.new(shot.user).upload(shot)
  rescue Airtable::DataError => e
    json = Oj.load(e.message)
    if json["error"]["type"] == "INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND"
      shot.user.identities.by_provider(:airtable).first.destroy
    else
      Appsignal.send_error(e) do |transaction|
        transaction.set_tags(shot_id: shot.id, user_id: shot.user_id)
      end
    end
  end
end
