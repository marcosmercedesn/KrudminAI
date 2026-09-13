require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/query_access_pipeline"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/ai/assistant"
require "krudmin_ai/ai/context_builder"
require "krudmin_ai/ai/multi_source_context"
require "krudmin_ai/ai/prompt_templates"
require "krudmin_ai/ai/reviewable_extraction"
require "krudmin_ai/ai/multi_source_analysis"
require "krudmin_ai/ai/approved_automation"

RSpec.describe "AI V1.1 and V2 contracts" do
  class AiV2Record
    class << self
      attr_accessor :records

      def transaction
        yield
      end
    end

    attr_accessor :id, :tenant, :title, :secret

    def initialize(id:, tenant:, title:, secret: nil)
      @id = id
      @tenant = tenant
      @title = title
      @secret = secret
    end

    def assign_attributes(attributes)
      attributes.each { |field, value| public_send("#{field}=", value) }
    end

    def save
      true
    end
  end

  class AiV2Relation
    def initialize(records)
      @records = records
    end

    def where(tenant:)
      self.class.new(@records.select { |record| record.tenant == tenant })
    end

    def limit(value)
      self.class.new(@records.first(value))
    end

    def map(&block)
      @records.map(&block)
    end

    def find(id)
      @records.find { |record| record.id == id } || raise(ActiveRecord::RecordNotFound)
    end
  end

  class AiV2Provider
    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def call(request)
      requests << request
      @response
    end
  end

  class AiV2Tracer
    attr_reader :traces

    def initialize
      @traces = []
    end

    def record(trace)
      traces << trace
    end
  end

  class AiV2Auditor
    attr_reader :events

    def initialize
      @events = []
    end

    def record(event)
      events << event
    end
  end

  let(:context) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north, roles: [ :manager ]) }
  let(:tracer) { AiV2Tracer.new }
  let(:auditor) { AiV2Auditor.new }
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model AiV2Record
      tenant_scope { |relation, access_context| relation.where(tenant: access_context.tenant) }
      policy_scope { |relation, _access_context| relation }
      tenant_record { |record, access_context| record.tenant == access_context.tenant }
      permit :title
      sortable :title
      default_sort_by :title
      authorize :update, ->(_record, _context) { true }
      authorize_field :title, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
      authorize_field :secret, read: ->(_record, _context) { false }, write: ->(_record, _context) { false }
      ai_field :title
      ai_field :secret
    end
  end
  let(:relation) { AiV2Relation.new(AiV2Record.records) }

  before do
    AiV2Record.records = [
      AiV2Record.new(id: 1, tenant: :north, title: "North ticket", secret: "north secret"),
      AiV2Record.new(id: 2, tenant: :south, title: "South ticket", secret: "south secret")
    ]
  end

  it "builds multi-source context from independently tenant-scoped, field-allowlisted sources" do
    context_result = KrudminAI::Ai::MultiSourceContextBuilder.new(context:).build(
      tickets: { resource:, relation: },
      related_tickets: { resource:, relation: }
    )

    expect(context_result.sources).to eq(
      tickets: [ { title: "North ticket" } ],
      related_tickets: [ { title: "North ticket" } ]
    )
    expect(context_result.sources.to_s).not_to include("secret", "South ticket")
  end

  it "returns a reviewable extraction draft with evidence and never persists provider proposals" do
    provider = AiV2Provider.new(attributes: { title: "Extracted title", secret: "forged secret" }, evidence: { title: [ "page 1" ] })
    draft = KrudminAI::Ai::ReviewableExtraction.new(context:, provider:, tracer:).call(
      resource:,
      relation:,
      prompt_template: "support/extract",
      fields: [ :title ],
      input: { document: "untrusted document" }
    )

    expect(draft).to have_attributes(attributes: { title: "Extracted title" }, evidence: { title: [ "page 1" ] }, status: :pending_review)
    expect(AiV2Record.records.first.title).to eq("North ticket")
    expect(provider.requests.first.context).to eq([ { title: "North ticket" } ])
    expect(tracer.traces.last).to have_attributes(status: :pending_review, output: nil)
  end

  it "runs read-only cross-record analysis from a reusable template with scoped evidence" do
    templates = KrudminAI::Ai::PromptTemplates.new
    template = templates.register(:duplicate_review, task: :cross_record_analysis, instructions: "Identify duplicate tickets.")
    provider = AiV2Provider.new(output: "No duplicates", action_references: [ { source: :tickets, record_id: 1 } ])
    result = KrudminAI::Ai::MultiSourceAnalysis.new(context:, provider:, provider_name: "primary", tracer:).call(
      task: :cross_record_analysis,
      sources: { tickets: { resource:, relation: } },
      template: template.to_h
    )

    expect(result).to have_attributes(status: :success, output: "No duplicates", evidence: [ { source: :tickets, record_id: 1 } ])
    expect(provider.requests.first.context).to eq(tickets: [ { title: "North ticket" } ])
    expect(provider.requests.first.mode).to eq(:read_only)
    expect(tracer.traces.last.status).to eq(:success)
    expect { templates.fetch(:duplicate_review, task: :dashboard_narrative) }.to raise_error(ArgumentError)
  end

  it "requires explicit approval, scopes the target lookup, and traces approved mutations with actor role context" do
    proposal = KrudminAI::Ai::AutomationProposal.new(:update, 1, { title: "Approved change" }, "source-fingerprint")
    executor = KrudminAI::Ai::ApprovedAutomation.new(
      context:,
      resource:,
      relation:,
      auditor:,
      tracer:,
      approval_policy: ->(_proposal, _context) { false }
    )

    expect(executor.call(proposal:)).to be_nil
    expect(AiV2Record.records.first.title).to eq("North ticket")
    expect(tracer.traces.last.status).to eq(:approval_required)

    approved_executor = KrudminAI::Ai::ApprovedAutomation.new(
      context:,
      resource:,
      relation:,
      auditor:,
      tracer:,
      approval_policy: ->(_proposal, _context) { true }
    )
    result = approved_executor.call(proposal:)

    expect(result).to be_success
    expect(AiV2Record.records.first.title).to eq("Approved change")
    expect(auditor.events.last.operation).to eq(:update)
    expect(tracer.traces.last).to have_attributes(actor: :morgan, roles: [ :manager ], tenant: :north, status: :success)
  end

  it "rejects a cross-tenant automation proposal before mutation" do
    proposal = KrudminAI::Ai::AutomationProposal.new(:update, 2, { title: "Forged update" }, "source-fingerprint")
    result = KrudminAI::Ai::ApprovedAutomation.new(
      context:,
      resource:,
      relation:,
      auditor:,
      tracer:,
      approval_policy: ->(_proposal, _context) { true }
    ).call(proposal:)

    expect(result).to be_nil
    expect(AiV2Record.records.last.title).to eq("South ticket")
    expect(tracer.traces.last.status).to eq(:forbidden)
  end
end
