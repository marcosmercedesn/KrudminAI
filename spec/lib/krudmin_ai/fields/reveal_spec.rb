require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/fields/reveal"

RSpec.describe KrudminAI::Fields::Reveal do
  Record = Struct.new(:id, :national_id)
  Auditor = Struct.new(:events) do
    def record(event) = events << event
  end

  let(:record) { Record.new(7, "123456789") }
  let(:auditor) { Auditor.new([]) }
  let(:context) { KrudminAI::AccessContext.new(actor: :compliance, tenant: :north, roles: [ :compliance ]) }
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      field :national_id, :masked
      authorize_field :national_id,
        read: ->(_record, _context) { true },
        write: ->(_record, _context) { false },
        reveal: ->(_record, access_context) { access_context.roles.include?(:compliance) }
    end
  end

  it "reveals only after separate read and reveal authorization and audits no value" do
    result = described_class.new(resource:, context:, auditor:).call(record:, field: :national_id)

    expect(result).to have_attributes(outcome: :success, value: "123456789")
    expect(auditor.events).to contain_exactly(have_attributes(operation: :reveal, record_id: 7, field: :national_id))
    expect(auditor.events.first.members).not_to include(:value)
  end

  it "denies a missing reveal decision without reading or auditing the value" do
    resource.authorize_field :national_id, read: ->(_record, _context) { true }, write: ->(_record, _context) { false }

    result = described_class.new(resource:, context:, auditor:).call(record:, field: :national_id)

    expect(result).to have_attributes(outcome: :forbidden, value: nil)
    expect(auditor.events).to be_empty
  end
end
