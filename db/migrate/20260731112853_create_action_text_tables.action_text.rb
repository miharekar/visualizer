# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[8.1]
  DISALLOWED_SELECTOR = "action-text-attachment, audio, embed, iframe, img, object, picture, script, source, style, video, figure[data-trix-attachment]"

  def up
    create_table :action_text_rich_texts, id: :uuid do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false, type: :uuid
      t.timestamps

      t.index %i[record_type record_id name], name: "index_action_text_rich_texts_uniqueness", unique: true
    end

    migrate_markdown(legacy_model("shots"), "Shot", %w[bean_notes espresso_notes private_notes])
    migrate_markdown(legacy_model("coffee_bags"), "CoffeeBag", %w[notes])
    migrate_markdown(legacy_model("changes"), "Update", %w[body])
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def legacy_model(table_name)
    Class.new(ActiveRecord::Base) do
      self.table_name = table_name
      self.inheritance_column = nil
    end
  end

  def migrate_markdown(model, record_type, attributes)
    rows = []

    model.find_each do |record|
      attributes.each do |name|
        value = record.public_send(name)
        rows << rich_text_row(record, record_type, name, value) if value.present?
      end

      if rows.size >= 1_000
        ActionText::RichText.insert_all!(rows) # rubocop:disable Rails/SkipsModelValidations
        rows.clear
      end
    end

    ActionText::RichText.insert_all!(rows) if rows.any? # rubocop:disable Rails/SkipsModelValidations
  end

  def rich_text_row(record, record_type, name, markdown)
    now = Time.current
    {record_type:, record_id: record.id, name:, body: markdown_html(markdown), created_at: now, updated_at: now}
  end

  def markdown_html(markdown)
    fragment = Nokogiri::HTML5.fragment(Kramdown::Document.new(markdown, input: "GFM").to_html)
    fragment.css(DISALLOWED_SELECTOR).remove
    fragment.css("[style]").each { it.remove_attribute("style") }
    fragment.css("pre > code").each do |code|
      language = code["class"].to_s[/language-([a-zA-Z0-9_-]+)/, 1]
      code.parent["data-language"] = language if language
    end
    ActionText::Content.new(fragment.to_html).to_html
  end
end
