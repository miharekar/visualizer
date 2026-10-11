# frozen_string_literal: true

ENV["OTEL_TRACES_EXPORTER"] = "none"
require "opentelemetry/sdk"
require "opentelemetry/sdk/trace/export/in_memory_span_exporter"
require "opentelemetry/sdk/trace/export/simple_span_processor"
require_relative "../config/initializers/opentelemetry"

exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
provider = OpenTelemetry::SDK::Trace::TracerProvider.new
provider.add_span_processor(VisualizerPrivacySpanProcessor.new)
provider.add_span_processor(
  OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
)
tracer = provider.tracer("visualizer-privacy-test")
span = tracer.start_span("fixture")
span.add_attributes(
  "duration.ms" => 12,
  "url.query" => "token=secret-query",
  "db.statement" => "SELECT 'secret-sql'",
  "db.query.text" => "secret-query-text",
  "email.to.address" => "person@example.invalid",
  "email.subject" => "secret-subject",
  "email.body" => "secret-body",
  "http.request.body" => "secret-request-body"
)
span.finish
attributes = exporter.finished_spans.first.attributes

raise "privacy filter retained sensitive span data" unless (
  attributes.keys & VisualizerPrivacySpanProcessor::SENSITIVE_KEYS
).empty?
raise "safe timing attribute was removed" unless attributes["duration.ms"] == 12

puts "visualizer-otel-privacy: PASS"
