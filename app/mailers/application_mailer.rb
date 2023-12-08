# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Miha Rekar <miha@visualizer.coffee>"
  layout "mailer"
end
