# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_11_22_082240) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "airtable_infos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "identity_id", null: false
    t.string "base_id"
    t.string "table_id"
    t.jsonb "table_fields"
    t.string "webhook_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_transaction"
    t.integer "last_cursor"
    t.index ["identity_id"], name: "index_airtable_infos_on_identity_id"
  end

  create_table "changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "excerpt"
    t.index ["slug"], name: "index_changes_on_slug", unique: true
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.jsonb "blob"
    t.datetime "expires_at"
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.string "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id", null: false
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "owner_id", null: false
    t.string "owner_type", null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "shared_shots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shot_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["code"], name: "index_shared_shots_on_code", unique: true
    t.index ["shot_id"], name: "index_shared_shots_on_shot_id"
    t.index ["user_id"], name: "index_shared_shots_on_user_id"
  end

  create_table "shot_informations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shot_id", null: false
    t.jsonb "data"
    t.jsonb "extra"
    t.jsonb "profile_fields"
    t.jsonb "timeframe"
    t.index ["shot_id"], name: "index_shot_informations_on_shot_id"
  end

  create_table "shots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_title"
    t.uuid "user_id"
    t.string "drink_tds"
    t.string "drink_ey"
    t.integer "espresso_enjoyment"
    t.string "bean_weight"
    t.string "drink_weight"
    t.string "grinder_model"
    t.string "grinder_setting"
    t.string "bean_brand"
    t.string "bean_type"
    t.string "roast_date"
    t.text "espresso_notes"
    t.string "sha"
    t.string "roast_level"
    t.text "bean_notes"
    t.string "s3_etag"
    t.string "barista"
    t.text "private_notes"
    t.float "duration"
    t.jsonb "metadata"
    t.string "airtable_id"
    t.index ["airtable_id"], name: "index_shots_on_airtable_id"
    t.index ["created_at"], name: "index_shots_on_created_at"
    t.index ["sha"], name: "index_shots_on_sha"
    t.index ["user_id", "created_at"], name: "index_shots_on_user_id_and_created_at"
    t.index ["user_id", "start_time"], name: "index_shots_on_user_id_and_start_time"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "skin"
    t.string "name"
    t.boolean "public", default: false
    t.boolean "supporter"
    t.string "timezone"
    t.boolean "admin"
    t.string "slug"
    t.boolean "hide_shot_times"
    t.string "github"
    t.jsonb "chart_settings"
    t.datetime "last_read_change"
    t.boolean "beta"
    t.string "stripe_customer_id"
    t.datetime "premium_expires_at"
    t.boolean "developer"
    t.string "temperature_unit"
    t.jsonb "metadata_fields"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "airtable_infos", "identities"
  add_foreign_key "identities", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "shared_shots", "shots"
  add_foreign_key "shared_shots", "users"
  add_foreign_key "shot_informations", "shots"
  add_foreign_key "shots", "users"
end
