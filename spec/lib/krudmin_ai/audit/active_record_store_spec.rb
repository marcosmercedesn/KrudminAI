require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/audit/active_record_store"
require "krudmin_ai/mutation_pipeline"

RSpec.describe KrudminAI::Audit::ActiveRecordStore do
  AuditEventRecord = Struct.new(:attributes, keyword_init: true)

  AuditStoreRelation = Class.new do
    attr_reader :operations

    def initialize(operations = [])
      @operations = operations
    end

    def where(value)
      self.class.new(operations + [ [ :where, value ] ])
    end

    def order(value)
      self.class.new(operations + [ [ :order, value ] ])
    end
  end

  let(:model) do
    Class.new do
      class << self
        attr_accessor :created_attributes

        def create!(attributes)
          self.created_attributes = attributes
        end

        def where(value)
          AuditStoreRelation.new.where(value)
        end
      end
    end
  end
  let(:context) { KrudminAI::AccessContext.new(actor: :operator, tenant: :north) }

  it "persists normalized audit event attributes" do
    event = KrudminAI::AuditEvent.new(:update, :operator, :north, [ :manager ], 4, { passengers: [ 7 ] })

    described_class.new(model:).record(event)

    expect(model.created_attributes).to include(
      event_type: "audit_event", actor_identifier: "operator", tenant: "north", operation: "update", record_identifier: "4"
    )
  end

  it "searches tenant-first before policy and declared filters" do
    store = described_class.new(model:)
    result = store.search(context:, policy_scope: ->(relation, _context) { relation.where(actor_identifier: "operator") }, operation: :update, record_type: :Widget)

    expect(result.operations).to eq([
      [ :where, { tenant: "north" } ], [ :where, { actor_identifier: "operator" } ], [ :where, { operation: "update" } ],
      [ :where, { record_type: "Widget" } ], [ :order, { created_at: :desc } ]
    ])
  end

  it "redacts configured sensitive metadata recursively" do
    event = AuditEventRecord.new(attributes: { "metadata" => { "secret" => "hidden", "safe" => { "token" => "hidden", "value" => "visible" } } })

    expect(described_class.new(model:).presentation(event).fetch("metadata")).to eq(
      "secret" => "[FILTERED]", "safe" => { "token" => "[FILTERED]", "value" => "visible" }
    )
  end
end
