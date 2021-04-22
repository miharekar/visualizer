# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Miha Rekar <miha@mr.si>"
  layout "mailer"
end
