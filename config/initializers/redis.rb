# frozen_string_literal: true

$redis = Redis.new(url: ENV.fetch("REDIS_URL", nil), ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}) # rubocop:disable Style/GlobalVars
