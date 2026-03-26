Scalar.setup do |config|
  config.configuration = {content: Rails.root.join("openapi.yaml").read}
  config.page_title = "Visualizer API"
end
