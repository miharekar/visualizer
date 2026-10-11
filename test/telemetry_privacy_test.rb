# frozen_string_literal: true

ENV["OTEL_TRACES_EXPORTER"] = "none"
require "opentelemetry/sdk"
require_relative "../config/initializers/opentelemetry"

tracer = OpenTelemetry.tracer_provider.tracer("visualizer-privacy-test")
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
attributes = span.to_span_data.attributes

raise "privacy filter retained sensitive span data" unless (
  attributes.keys & VisualizerPrivacySpanProcessor::SENSITIVE_KEYS
).empty?
raise "safe timing attribute was removed" unless attributes["duration.ms"] == 12

puts "visualizer-otel-privacy: PASS"
