require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/query_access_pipeline"
require "krudmin_ai/ai/context_builder"
require "krudmin_ai/ai/tool_router"
require "krudmin_ai/ai/assistant"

RSpec.describe KrudminAI::Ai::Assistant do
  AiRecord = Data.define(:tenant, :roles, :title, :secret)

  AiRelation = Data.define(:records) do
    def where(tenant:)
      self.class.new(records.select { |record| record.tenant == tenant })
    end

    def policy(roles)
      self.class.new(records.select { |record| (record.roles & roles).any? })
    end

    def limit(value)
      self.class.new(records.first(value))
    end

    def map(&block)
      records.map(&block)
    end

    def order(_sort)
      self
    end

    def offset(_value)
      self
    end
  end

  class RecordingProvider
    attr_reader :requests

    def initialize(response = { output: "Safe answer" })
      @response = response
      @requests = []
    end

    def call(request)
      requests << request
      @response
    end
  end

  class RecordingTracer
    attr_reader :traces

    def initialize
      @traces = []
    end

    def record(trace)
      traces << trace
    end
  end

  class FailingProvider
    def call(_request)
      raise "provider unavailable"
    end
  end

  let(:context) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north, roles: [ :manager ]) }
  let(:relation) do
    AiRelation.new([
      AiRecord.new(:north, [ :manager ], "North ticket", "north secret"),
      AiRecord.new(:north, [ :auditor ], "Denied ticket", "denied secret"),
      AiRecord.new(:south, [ :manager ], "South ticket", "south secret")
    ])
  end
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model AiRecord
      tenant_scope { |scoped_relation, access_context| scoped_relation.where(tenant: access_context.tenant) }
      policy_scope { |scoped_relation, access_context| scoped_relation.policy(access_context.roles) }
      sortable :title
      default_sort_by :title
      authorize_field :title, read: ->(_record, _context) { true }, write: ->(_record, _context) { false }
      ai_field :title
    end
  end
  let(:provider) { RecordingProvider.new }
  let(:tracer) { RecordingTracer.new }
  let(:assistant) { described_class.new(context:, provider:, provider_name: "test-provider", tracer:) }

  it "supports the four read-only task types with allowlisted, scoped context" do
    described_class::TASKS.each do |task|
      result = assistant.call(task:, resource:, relation:, prompt_template: "support/#{task}")

      expect(result).to be_success
    end

    expect(provider.requests.first.context).to eq([ { title: "North ticket" } ])
    expect(provider.requests.first.mode).to eq(:read_only)
    expect(tracer.traces.last).to have_attributes(actor: :morgan, provider: "test-provider", status: :success)
  end

  it "blocks unauthorized data before the provider is called" do
    resource.policy_scope { |_scoped_relation, _access_context| false }

    result = assistant.call(task: :record_summary, resource:, relation:, prompt_template: "support/summary")

    expect(result.status).to eq(:forbidden)
    expect(provider.requests).to be_empty
    expect(tracer.traces.last.scoped_context_fingerprint).to be_nil
  end

  it "does not expose records from another tenant or fields outside the allowlist" do
    assistant.call(task: :record_q_and_a, resource:, relation:, prompt_template: "support/q-and-a")

    expect(provider.requests.first.context).to eq([ { title: "North ticket" } ])
    expect(provider.requests.first.context.to_s).not_to include("secret", "South ticket", "Denied ticket")
  end

  it "omits an AI allowlisted field when its field policy denies read access" do
    resource.authorize_field :title, read: ->(_record, _context) { false }, write: ->(_record, _context) { false }

    assistant.call(task: :record_q_and_a, resource:, relation:, prompt_template: "support/q-and-a")

    expect(provider.requests.first.context).to eq([ {} ])
  end

  it "rejects unsafe provider tool calls and traces the rejection" do
    unsafe_provider = RecordingProvider.new(output: "Attempting mutation", tool_calls: [ { name: :delete_record } ])
    unsafe_assistant = described_class.new(context:, provider: unsafe_provider, provider_name: "test-provider", tracer:)

    result = unsafe_assistant.call(task: :record_summary, resource:, relation:, prompt_template: "support/summary")

    expect(result.status).to eq(:unsafe_tool_call)
    expect(tracer.traces.last.status).to eq(:unsafe_tool_call)
  end

  it "requires explicit approval before accepting a mutation-capable request" do
    result = assistant.call(
      task: :record_summary,
      resource:,
      relation:,
      prompt_template: "support/summary",
      requested_action: { name: :update_ticket }
    )

    expect(result.status).to eq(:approval_required)
    expect(provider.requests).to be_empty
  end

  it "contains provider failures and records a failure trace without provider details" do
    result = described_class.new(context:, provider: FailingProvider.new, provider_name: "offline-provider", tracer:).call(
      task: :record_summary,
      resource:,
      relation:,
      prompt_template: "support/summary"
    )

    expect(result).to have_attributes(status: :provider_failed, output: nil)
    expect(result.errors).to eq([ { code: :provider_failed, detail: "The AI provider is temporarily unavailable" } ])
    expect(tracer.traces.last).to have_attributes(provider: "offline-provider", status: :provider_failed)
  end
end
