require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/ai/reviewable_extraction"
require "krudmin_ai/ai/active_record_proposal_store"

RSpec.describe KrudminAI::Ai::ActiveRecordProposalStore do
  ProposalStoreRecord = Struct.new(:id, :tenant, :actor_identifier, :operation, :record_identifier, :attributes, :evidence, :source_fingerprint, :status, :reviewer_identifier, keyword_init: true) do
    def update!(values) = values.each { |key, value| public_send("#{key}=", value) }
  end

  let(:model) do
    Class.new do
      class << self
        attr_accessor :records
        def create!(attributes) = ProposalStoreRecord.new(id: records.length + 1, **attributes).tap { |record| records << record }
        def find_by(attributes) = records.find { |record| attributes.all? { |key, value| record.public_send(key) == value } }
      end
    end.tap { |klass| klass.records = [] }
  end
  let(:north) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north) }
  let(:south) { KrudminAI::AccessContext.new(actor: :sam, tenant: :south) }
  let(:draft) { KrudminAI::Ai::ReviewDraft.new({ priority: "high" }, { priority: "sensitive evidence" }, "fingerprint", :pending_review) }

  it "requires same-tenant review before an approved proposal can be found" do
    store = described_class.new(model:)
    proposal = store.create(context: north, draft:, operation: :update, record_id: 4)

    expect(proposal.evidence).to eq(priority: "[redacted]")
    expect(store.approve(proposal, context: south).status).to eq("pending_review")
    expect(store.approve(proposal, context: north)).to have_attributes(status: "approved", reviewer_identifier: "morgan")
    expect(store.find_approved(context: north, identifier: proposal.id)).to equal(proposal)
    expect(store.find_approved(context: south, identifier: proposal.id)).to be_nil
  end
end
