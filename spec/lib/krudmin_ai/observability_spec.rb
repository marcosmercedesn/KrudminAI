require "logger"
require "stringio"
require "spec_helper"
require "rails"
require "action_controller/railtie"
require "krudmin_ai"

RSpec.describe KrudminAI::Observability do
  class ObservabilityRecordingMetrics
    attr_reader :events

    def initialize
      @events = []
    end

    def increment(name, tags:)
      events << { name:, tags: }
    end
  end

  class ObservabilityRecordingTracer
    attr_reader :events

    def initialize
      @events = []
    end

    def record(event:, attributes:)
      events << { event:, attributes: }
    end
  end

  around do |example|
    configuration = KrudminAI.config
    original = [configuration.observability_logger, configuration.metrics_provider, configuration.tracing_provider]
    example.run
  ensure
    configuration.observability_logger, configuration.metrics_provider, configuration.tracing_provider = original
  end

  it "correlates redacted structured logs, notifications, metrics, and traces" do
    output = StringIO.new
    metrics = ObservabilityRecordingMetrics.new
    tracer = ObservabilityRecordingTracer.new
    KrudminAI.configure do |config|
      config.observability_logger = Logger.new(output)
      config.metrics_provider = metrics
      config.tracing_provider = tracer
    end
    notification = nil
    subscription = ActiveSupport::Notifications.subscribe("krudmin_ai.mutation.completed") do |_name, _started, _finished, _id, payload|
      notification = payload
    end

    payload = described_class.with_correlation("request-42") do
      described_class.emit(
        "mutation.completed",
        operation: :update,
        outcome: :success,
        resource: "Ticket",
        tenant: "northwind",
        fields: { title: "Visible only to the form", secret: "do-not-log" },
        audit_event: { record_id: 7 },
        output: "AI response"
      )
    end

    expect(payload).to include(event: "mutation.completed", correlation_id: "request-42", operation: :update, outcome: :success)
    expect(notification).to eq(payload)
    expect([payload, output.string, metrics.events, tracer.events].to_s).not_to include("northwind", "Visible only to the form", "do-not-log", "AI response")
    expect(metrics.events).to eq([{ name: "krudmin_ai.mutation.completed", tags: { event: "mutation.completed", operation: "update", outcome: "success", resource: "Ticket" } }])
    expect(tracer.events.first.dig(:attributes, :correlation_id)).to eq("request-42")
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  it "isolates telemetry adapter failures from the protected operation" do
    KrudminAI.configure do |config|
      config.metrics_provider = Class.new { def increment(*) = raise "unavailable" }.new
    end

    expect { described_class.emit("request.completed", status: 200, tenant: "northwind") }.not_to raise_error
  end
end