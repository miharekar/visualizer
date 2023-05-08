# frozen_string_literal: true

class OauthWrapper < SimpleDelegator
  extend Memoist

  memoize def identifiers
    {provider:, uid:}
  end

  memoize def identifiers_with_blob
    identifiers.merge(blob: self)
  end

  memoize def identifiers_with_blob_and_token
    identifiers_with_blob.merge(
      token:,
      refresh_token:,
      expires_at: Time.zone.at(expires_at)
    )
  end

  %i[token refresh_token expires_at].each do |credential|
    define_method(credential) { dig(:credentials, credential) }
  end
end
