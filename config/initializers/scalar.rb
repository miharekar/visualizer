Scalar.setup do |config|
  config.specification = Rails.root.join("openapi.yaml").read
  config.page_title = "Visualizer API"
end
