# frozen_string_literal: true

# Self-hosted builds deliberately ship an empty credentials document.  The
# key only decrypts this empty file; integrations are configured through env.
require "active_support/encrypted_file"
require "pathname"

key = "00000000000000000000000000000000"
root = Pathname(__dir__).parent
key_path = root.join("config/master.key")
content_path = root.join("config/credentials/production.yml.enc")
key_path.write(key)
key_path.chmod(0o600)
encrypted = ActiveSupport::EncryptedFile.new(
  content_path: content_path,
  key_path: key_path,
  env_key: "RAILS_MASTER_KEY",
  raise_if_missing_key: true
)
encrypted.write("")
content_path.chmod(0o600)
