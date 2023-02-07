# frozen_string_literal: true

RorVsWild.start(api_key: Rails.application.credentials[:rorvswild]) if Rails.application.credentials[:rorvswild].present?
