# frozen_string_literal: true

class SponsorshipsMailer < ApplicationMailer
  def webhook(payload)
    @payload = payload
    mail(to: "miha@mr.si", subject: "Sponsorships webhook triggered")
  end
end
