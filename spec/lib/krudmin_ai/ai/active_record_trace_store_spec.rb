require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/ai/assistant"
require "krudmin_ai/ai/active_record_trace_store"

RSpec.describe KrudminAI::Ai::ActiveRecordTraceStore do
  TraceRelation = Class.new do
    attr_reader :operations

    def initialize(operations = []) = @operations = operations
    def where(value) = self.class.new(operations + [ [ :where, value ] ])
    def order(value) = self.class.new(operations + [ [ :order, value ] ])
  end

  let(:model) do
    Class.new do
      class << self
        attr_accessor :created
        def create!(attributes) = self.created = attributes
        def where(value) = TraceRelation.new.where(value)
      end
    end
  end
  let(:context) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north) }

  it "persists redacted traces and searches tenant-first" do
    trace = KrudminAI::Ai::Trace.new(:morgan, "support/summary", "primary", "fingerprint", "Sensitive output", [], :queued)
    store = described_class.new(model:)

    store.recorder_for(context).record(trace)

    expect(model.created).to include(tenant: "north", status: "queued", output: "[redacted]")
    expect(model.created.to_s).not_to include("Sensitive output")
    expect(store.search(context:, statuses: [ :completed ], query: "support/summary").operations).to eq([
      [ :where, { tenant: "north" } ], [ :where, { status: [ "completed" ] } ], [ :where, { prompt_template: "support/summary" } ], [ :order, { created_at: :desc } ]
    ])
  end
end
