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

ActiveRecord::Schema[8.0].define(version: 2024_12_13_111131) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

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
    t.string "webhook_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_transaction"
    t.integer "last_cursor"
    t.jsonb "tables"
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

  create_table "coffee_bags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "roaster_id", null: false
    t.string "name"
    t.date "roast_date"
    t.string "roast_level"
    t.string "country"
    t.string "region"
    t.string "farm"
    t.string "farmer"
    t.string "variety"
    t.string "elevation"
    t.string "processing"
    t.string "harvest_time"
    t.string "quality_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "airtable_id"
    t.string "url"
    t.string "tasting_notes"
    t.index ["airtable_id"], name: "index_coffee_bags_on_airtable_id"
    t.index ["roaster_id"], name: "index_coffee_bags_on_roaster_id"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "stripe_id"
    t.string "name"
    t.string "email"
    t.integer "amount"
    t.jsonb "address"
    t.jsonb "payments"
    t.jsonb "refunds"
    t.index ["stripe_id"], name: "index_customers_on_stripe_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
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

  create_table "roasters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "airtable_id"
    t.index ["airtable_id"], name: "index_roasters_on_airtable_id"
    t.index ["user_id", "name"], name: "index_roasters_on_user_id_and_name", unique: true
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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
    t.jsonb "brewdata"
    t.index ["shot_id"], name: "index_shot_informations_on_shot_id"
  end

  create_table "shot_tags", id: false, force: :cascade do |t|
    t.uuid "shot_id", null: false
    t.uuid "tag_id", null: false
    t.index ["shot_id"], name: "index_shot_tags_on_shot_id"
    t.index ["tag_id", "shot_id"], name: "index_shot_tags_on_tag_id_and_shot_id", unique: true
    t.index ["tag_id"], name: "index_shot_tags_on_tag_id"
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
    t.string "barista"
    t.text "private_notes"
    t.float "duration"
    t.jsonb "metadata"
    t.string "airtable_id"
    t.boolean "public"
    t.uuid "coffee_bag_id"
    t.index ["airtable_id"], name: "index_shots_on_airtable_id"
    t.index ["bean_brand"], name: "index_shots_on_bean_brand", opclass: :gin_trgm_ops, using: :gin
    t.index ["bean_type"], name: "index_shots_on_bean_type", opclass: :gin_trgm_ops, using: :gin
    t.index ["coffee_bag_id"], name: "index_shots_on_coffee_bag_id"
    t.index ["created_at"], name: "index_shots_on_created_at"
    t.index ["sha"], name: "index_shots_on_sha"
    t.index ["start_time"], name: "index_shots_on_start_time"
    t.index ["user_id"], name: "index_shots_on_user_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.string "stripe_id"
    t.string "status"
    t.string "interval"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "cancel_at"
    t.datetime "cancelled_at"
    t.jsonb "cancellation_details"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["stripe_id"], name: "index_subscriptions_on_stripe_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "slug"], name: "index_tags_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "password_digest", default: "", null: false
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
    t.jsonb "unsubscribed_from"
    t.string "decent_email"
    t.string "decent_token"
    t.boolean "coffee_management_enabled"
    t.string "date_format"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "airtable_infos", "identities"
  add_foreign_key "coffee_bags", "roasters"
  add_foreign_key "customers", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "roasters", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "shared_shots", "shots"
  add_foreign_key "shared_shots", "users"
  add_foreign_key "shot_informations", "shots"
  add_foreign_key "shot_tags", "shots"
  add_foreign_key "shot_tags", "tags"
  add_foreign_key "shots", "coffee_bags"
  add_foreign_key "shots", "users"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "tags", "users"
end
