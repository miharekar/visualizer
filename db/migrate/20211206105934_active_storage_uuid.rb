# frozen_string_literal: true

class ActiveStorageUuid < ActiveRecord::Migration[7.0]
  class MigrationAttachment < ApplicationRecord
    self.table_name = :active_storage_attachments
  end

  class MigrationBlob < ApplicationRecord
    self.table_name = :active_storage_blobs
  end

  def up
    attachments = MigrationAttachment.all.map(&:attributes)
    blobs = MigrationBlob.all.map(&:attributes)

    drop_table :active_storage_attachments
    drop_table :active_storage_variant_records
    drop_table :active_storage_blobs

    create_table :active_storage_blobs, id: :uuid do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum, null: false
      t.datetime :created_at, null: false

      t.index [:key], unique: true
    end

    create_table :active_storage_attachments, id: :uuid do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false, type: :uuid
      t.references :blob, null: false, type: :uuid

      t.datetime :created_at, null: false

      t.index %i[record_type record_id name blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :active_storage_variant_records, id: :uuid do |t|
      t.belongs_to :blob, null: false, index: false, type: :uuid
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    MigrationAttachment.reset_column_information
    MigrationBlob.reset_column_information

    mapping = {}

    blobs.each do |blob|
      id = blob["id"]
      new_blob = MigrationBlob.create!(blob.except("id"))
      mapping[id] = new_blob.id
    end

    attachments.each do |attachment|
      MigrationAttachment.create!(
        attachment.except("id").merge("blob_id" => mapping[attachment["blob_id"]])
      )
    end
  end
end
