require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/ai/durable_proposal_executor"

RSpec.describe KrudminAI::Ai::DurableProposalExecutor do
  Proposal = Data.define(:operation, :record_identifier, :attributes, :source_fingerprint)

  let(:context) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north) }

  it "does not call automation for a proposal outside the current tenant or review state" do
    store = instance_double("ProposalStore")
    automation = instance_double("ApprovedAutomation")
    allow(store).to receive(:find_approved).with(context:, identifier: "42").and_return(nil)

    expect(automation).not_to receive(:call)
    expect(described_class.new(proposal_store: store, automation:).call(context:, proposal_id: "42")).to be_nil
  end

  it "delegates only a stored approved proposal to the normal automation boundary" do
    proposal = Proposal.new("update", "4", { "priority" => "high" }, "fingerprint")
    store = instance_double("ProposalStore")
    automation = instance_double("ApprovedAutomation")
    allow(store).to receive(:find_approved).with(context:, identifier: "42").and_return(proposal)

    expect(automation).to receive(:call).with(
      proposal: have_attributes(operation: :update, record_id: "4", attributes: { priority: "high" }, source_fingerprint: "fingerprint"),
      params: {}
    )
    described_class.new(proposal_store: store, automation:).call(context:, proposal_id: "42")
  end
end
