require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/mutation_response"

RSpec.describe KrudminAI::MutationPipeline do
  class FakeRecord
    attr_reader :id, :attributes, :errors, :save_calls, :destroy_calls

    def initialize(id: 7, save_result: true, destroy_result: true, errors: [])
      @id = id
      @save_result = save_result
      @destroy_result = destroy_result
      @errors = errors
      @attributes = {}
      @save_calls = 0
      @destroy_calls = 0
    end

    def assign_attributes(attributes)
      @attributes.merge!(attributes)
    end

    def save
      @save_calls += 1
      @save_result
    end

    def destroy
      @destroy_calls += 1
      @destroy_result
    end
  end

  class RecordingAuditor
    attr_reader :events

    def initialize
      @events = []
    end

    def record(event)
      events << event
    end
  end

  let(:actor) { Object.new }
  let(:tenant) { Object.new }
  let(:context) { KrudminAI::AccessContext.new(actor:, tenant:, roles: %i[operator manager]) }
  let(:auditor) { RecordingAuditor.new }
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model FakeRecord
      tenant_record { |_record, _context| true }
      authorize(:create) { |_record, access_context| access_context.roles.include?(:operator) }
      authorize(:update) { |_record, access_context| access_context.roles.include?(:manager) }
      authorize(:destroy) { |_record, access_context| access_context.roles.include?(:manager) }
    end
  end

  it "authorizes, persists, and audits a create mutation" do
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor:).call(operation: :create, record:, attributes: { name: "North" })

    expect(result).to be_success
    expect(record.attributes).to eq(name: "North")
    expect(auditor.events.first).to have_attributes(operation: :create, actor:, tenant:, roles: %i[operator manager], record_id: 7)
  end

  it "authorizes, persists, and audits an update mutation" do
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor:).call(operation: :update, record:, attributes: { name: "East" })

    expect(result).to be_success
    expect(record).to have_attributes(attributes: { name: "East" }, save_calls: 1)
    expect(auditor.events.first.operation).to eq(:update)
  end

  it "authorizes, persists, and audits a destroy mutation" do
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor:).call(operation: :destroy, record:)

    expect(result).to be_success
    expect(record.destroy_calls).to eq(1)
    expect(auditor.events.first.operation).to eq(:destroy)
  end

  it "does not mutate or audit when the action policy rejects the actor" do
    resource.authorize(:destroy) { |_record, _context| false }
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor:).call(operation: :destroy, record:)

    expect(result).to have_attributes(outcome: :forbidden, record: nil)
    expect(record.destroy_calls).to eq(0)
    expect(auditor.events).to be_empty
  end

  it "does not mutate a record outside the current tenant" do
    resource.tenant_record { |_record, _context| false }
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor:).call(operation: :update, record:, attributes: { name: "South" })

    expect(result.outcome).to eq(:forbidden)
    expect(record.attributes).to be_empty
    expect(auditor.events).to be_empty
  end

  it "returns validation errors without creating an audit event" do
    record = FakeRecord.new(save_result: false, errors: ["Name cannot be blank"])

    result = described_class.new(resource:, context:, auditor:).call(operation: :update, record:, attributes: { name: "" })

    expect(result).to have_attributes(outcome: :invalid, errors: [{ code: :invalid, detail: "Name cannot be blank" }])
    expect(auditor.events).to be_empty
  end

  it "requires an audit sink before persistence" do
    record = FakeRecord.new

    result = described_class.new(resource:, context:, auditor: nil).call(operation: :destroy, record:)

    expect(result.outcome).to eq(:configuration_error)
    expect(record.destroy_calls).to eq(0)
  end

  it "normalizes success and validation responses for HTML, JSON, and Turbo Stream" do
    success = described_class.new(resource:, context:, auditor:).call(operation: :create, record: FakeRecord.new)
    invalid = described_class.new(resource:, context:, auditor:).call(
      operation: :update, record: FakeRecord.new(save_result: false, errors: ["Invalid"])
    )

    expect(KrudminAI::MutationResponseAdapter.for(success, format: :html)).to have_attributes(status: 303)
    expect(KrudminAI::MutationResponseAdapter.for(success, format: :json)).to have_attributes(status: 201)
    expect(KrudminAI::MutationResponseAdapter.for(success, format: :turbo_stream).payload[:template])
      .to eq("krudmin_ai/mutations/create_success")
    expect(KrudminAI::MutationResponseAdapter.for(invalid, format: :json)).to have_attributes(status: 422)
    expect(KrudminAI::MutationResponseAdapter.for(invalid, format: :html).payload[:template]).to eq(:edit)
    expect(KrudminAI::MutationResponseAdapter.for(invalid, format: :turbo_stream).payload[:template])
      .to eq("krudmin_ai/mutations/update_error")
  end
end