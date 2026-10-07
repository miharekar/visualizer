HotCell.root = ENV.fetch("HOTCELL_ROOT") { Rails.root.join("tmp/hotcell-sockets").to_s if Rails.env.development? }
HotCell.group = ENV["HOTCELL_GROUP"]
HotCell.register "active_storage"

class HotCellImageTransformer < ActiveStorage::Transformers::Transformer
  class Operation < HotCell::Client
    hotcell "active_storage"
    operation "active_storage.transformers.image.vips"
  end

  private

  def process(file, format:)
    output = Tempfile.new(["hotcell", ".#{format}"], binmode: true)
    begin
      File.open(file.path, "rb") do |input|
        File.open(output.path, "wb") do |writable|
          Operation.perform_in_hotcell [input], [writable], {format: format.to_s, operations: transformations}
        end
      end
      output.tap(&:rewind)
    rescue
      output.close!
      raise
    end
  end
end

Rails.application.config.after_initialize { HotCell.describe_cells if Rails.env.production? }
